require "rails_helper"
require "requests/shared_examples/comment_hide_or_unhide_request"

RSpec.describe "Comments", type: :request do
  let(:user) { create(:user) }
  let(:article) { create(:article, user: user) }
  let(:podcast) { create(:podcast) }
  let(:podcast_episode) { create(:podcast_episode, podcast_id: podcast.id) }
  let!(:comment) { create(:comment, commentable: article, user: user) }

  describe "GET comment index" do
    it "returns 200" do
      get comment.path
      expect(response).to have_http_status(:ok)
    end

    it "displays a comment" do
      get comment.path
      expect(response.body).to include(comment.processed_html)
    end

    it "displays full discussion text" do
      get comment.path
      expect(response.body).to include("Full discussion")
    end

    it "renders user payment pointer if set" do
      article.user.update_column(:payment_pointer, "test-pointer-for-comments")
      get "#{article.path}/comments"
      expect(response.body).to include "author-payment-pointer"
      expect(response.body).to include "test-pointer-for-comments"
    end

    it "does not render payment pointer if not set" do
      get "#{article.path}/comments"
      expect(response.body).not_to include "author-payment-pointer"
    end

    context "when the comment is a root" do
      it "displays the comment hidden message if the comment is hidden" do
        comment.update(hidden_by_commentable_user: true)
        get comment.path
        hidden_comment_message = "Comment hidden by post author - thread only visible in this permalink"
        expect(response.body).to include(hidden_comment_message)
      end

      it "displays the comment anyway if it is hidden" do
        comment.update(hidden_by_commentable_user: true)
        get comment.path
        expect(response.body).to include(comment.processed_html)
      end
    end

    context "when the comment is a child comment" do
      let(:child) { create(:comment, parent: comment, commentable: article, user: user) }

      it "displays proper button and text for child comment" do
        get child.path
        expect(response.body).to include(CGI.escapeHTML(comment.title(150)))
        expect(response.body).to include(child.processed_html)
      end

      it "does not display the comment if it is hidden" do
        child.update(hidden_by_commentable_user: true)
        get comment.path
        expect(response.body).not_to include child.processed_html
      end
    end

    context "when the comment is two levels nested and hidden" do # child of a child
      let(:child) { create(:comment, parent: comment, commentable: article, user: user) }
      let(:child_of_child) do
        create(:comment, parent_id: child.id, commentable: article, user: user, hidden_by_commentable_user: true)
      end

      it "does not display the hidden comment in the child's permalink" do
        get child.path
        expect(response.body).not_to include(child_of_child.processed_html)
      end

      it "does not display the hidden comment in the article's comments section" do
        get "#{article.path}/comments"
        expect(response.body).not_to include(child_of_child.processed_html)
      end
    end

    context "when the comment is a sibling of a child comment and is hidden" do
      let(:child) { create(:comment, parent: comment, commentable: article, user: user) }
      let(:sibling) do
        create(:comment, parent: comment, commentable: article, user: user, hidden_by_commentable_user: true)
      end

      it "does not display the hidden comment in the article's comments section" do
        get "#{article.path}/comments"
        expect(response.body).not_to include(sibling.processed_html)
      end

      it "shows the hidden comments message in the comment's permalink" do
        get sibling.path
        hidden_comment_message = "Comment hidden by post author - thread only visible in this permalink"
        expect(response.body).to include(hidden_comment_message)
      end

      it "does not show the sibling comment in the child's comment permalink" do
        get child.path
        expect(response.body).not_to include(sibling.processed_html)
      end

      it "shows the comment in the permalink" do
        get sibling.path
        expect(response.body).to include(sibling.processed_html)
      end
    end

    context "when the comment is three levels nested and hidden" do # child of a child of a child
      let(:child) { create(:comment, parent: comment, commentable: article, user: user) }
      let(:second_level_child) { create(:comment, parent: child, commentable: article, user: user) }
      let(:third_level_child) do
        create(:comment, parent: second_level_child, commentable: article, user: user, hidden_by_commentable_user: true)
      end
      let(:fourth_level_child) do
        create(:comment, parent_id: third_level_child.id, commentable: article, user: user)
      end

      it "does not show the hidden comment in the article's comments section" do
        get "#{article.path}/comments"
        expect(response.body).not_to include(third_level_child.processed_html)
      end

      it "does not show the hidden comment's children in the article's comments section" do
        fourth_level_child
        get "#{article.path}/comments"
        expect(response.body).not_to include(fourth_level_child.processed_html)
      end

      it "does not show the hidden comment in its parent's permalink" do
        get second_level_child.path
        expect(response.body).not_to include(third_level_child.processed_html)
      end

      it "does not show the hidden comment's child in its parent's permalink" do
        fourth_level_child
        get second_level_child.path
        expect(response.body).not_to include(fourth_level_child.processed_html)
      end

      it "shows the comment in the permalink" do
        get third_level_child.path
        expect(response.body).to include(third_level_child.processed_html)
      end

      it "shows the fourth level child in the hidden comment's permalink" do
        fourth_level_child
        get third_level_child.path
        expect(response.body).to include(fourth_level_child.processed_html)
      end
    end

    context "when the comment is for a podcast's episode" do
      it "works" do
        podcast_comment = create(:comment, commentable: podcast_episode, user: user)

        get podcast_comment.path
        expect(response).to have_http_status(:ok)
      end
    end

    context "when the article is unpublished" do
      before do
        new_markdown = article.body_markdown.gsub("published: true", "published: false")
        comment
        article.update(body_markdown: new_markdown)
      end

      it "raises a Not Found error" do
        expect { get comment.path }.to raise_error("Not Found")
      end
    end

    context "when the article is deleted" do
      it "index action renders deleted_commentable_comment view" do
        article = create(:article)
        comment = create(:comment, commentable: article)

        article.destroy

        get comment.path
        expect(response.body).to include("Comment from a deleted article or podcast")
      end
    end

    context "when the podcast episode is deleted" do
      it "renders deleted_commentable_comment view" do
        podcast_comment = create(:comment, commentable: podcast_episode)
        podcast_episode.destroy

        get podcast_comment.path
        expect(response.body).to include("Comment from a deleted article or podcast")
      end
    end
  end

  describe "GET /:username/:slug/comments/:id_code/edit" do
    context "when not logged-in" do
      it "returns unauthorized error" do
        expect do
          get "/#{user.username}/#{article.slug}/comments/#{comment.id_code_generated}/edit"
        end.to raise_error(Pundit::NotAuthorizedError)
      end
    end

    context "when logged-in" do
      before do
        sign_in user
      end

      it "returns 200" do
        get "/#{user.username}/#{article.slug}/comments/#{comment.id_code_generated}/edit"
        expect(response).to have_http_status(:ok)
      end

      it "returns the comment" do
        get "/#{user.username}/#{article.slug}/comments/#{comment.id_code_generated}/edit"
        expect(response.body).to include CGI.escapeHTML(comment.body_markdown)
      end
    end

    context "when the article is deleted" do
      before do
        sign_in user
      end

      it "edit action returns 200" do
        article = create(:article, user: user)
        comment = create(:comment, commentable: article, user: user)

        article.destroy

        get "/#{user.username}/#{article.slug}/comments/#{comment.id_code_generated}/edit"
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "PUT /comments/:id" do
    before do
      sign_in user
    end

    it "does not raise a StandardError for invalid liquid tags" do
      put "/comments/#{comment.id}",
          params: { comment: { body_markdown: "{% gist flsnjfklsd %}" } }

      expect(response).to have_http_status(:ok)
      expect(flash[:error]).not_to be_nil
    end

    context "when the article is deleted" do
      it "updates body markdown" do
        article = create(:article, user: user)
        comment = create(:comment, commentable: article, user: user)

        article.destroy

        params = { comment: { body_markdown: "{edited comment}" } }
        put "/comments/#{comment.id}", params: params

        comment.reload
        expect(comment.processed_html).to include("edited comment")
      end
    end
  end

  describe "POST /comments/preview" do
    it "returns 401 if user is not logged in" do
      post "/comments/preview",
           params: { comment: { body_markdown: "hi" } },
           headers: { HTTP_ACCEPT: "application/json" }
      expect(response).to have_http_status(:unauthorized)
    end

    context "when logged-in" do
      before do
        sign_in user
        post "/comments/preview",
             params: { comment: { body_markdown: "hi" } },
             headers: { HTTP_ACCEPT: "application/json" }
      end

      it "returns 200 on good request" do
        expect(response).to have_http_status(:ok)
      end

      it "returns json" do
        expect(response.media_type).to eq("application/json")
      end
    end
  end

  describe "POST /comments" do
    let(:base_comment_params) do
      {
        comment: {
          commentable_id: article.id,
          commentable_type: "Article",
          user: user,
          body_markdown: "New comment #{rand(10)}"
        }
      }
    end

    context "when part of field test" do
      before do
        sign_in user
        allow(Users::RecordFieldTestEventWorker).to receive(:perform_async)
      end

      it "converts field test" do
        post "/comments", params: base_comment_params

        expected_args = [user.id, "user_creates_comment"]
        expect(Users::RecordFieldTestEventWorker).to have_received(:perform_async).with(*expected_args)
      end
    end
  end

  describe "PATCH /comments/:comment_id/hide" do
    include_examples "PATCH /comments/:comment_id/hide or unhide", path: "hide", hidden: "true"

    context "with notifications" do
      let(:user2) { create(:user) }
      let(:article)  { create(:article, :with_notification_subscription, user: user) }
      let(:comment)  { create(:comment, commentable: article, user: user2) }

      before do
        sign_in user
        Notification.send_new_comment_notifications_without_delay(comment)
      end

      it "Delete notification when comment is hidden" do
        notification = user.notifications.last
        patch "/comments/#{comment.id}/hide", headers: { HTTP_ACCEPT: "application/json" }
        expect(Notification.exists?(id: notification.id)).to eq(false)
      end
    end
  end

  describe "PATCH /comments/:comment_id/unhide" do
    include_examples "PATCH /comments/:comment_id/hide or unhide", path: "unhide", hidden: "false"
  end

  describe "DELETE /comments/:comment_id" do
    # we're using local article and comments, to avoid removing data used by other tests,
    # which will incur in ordering issues
    let!(:article) { create(:article, user: user) }
    let!(:comment) { create(:comment, commentable: article, user: user) }

    before { sign_in user }

    it "deletes a comment if the article is still present" do
      delete "/comments/#{comment.id}"

      expect(Comment.find_by(id: comment.id)).to be_nil
      expect(response).to redirect_to(comment.commentable.path)
      expect(flash[:notice]).to eq("Comment was successfully deleted.")
    end

    it "deletes a comment if the article has been deleted" do
      article.destroy!

      delete "/comments/#{comment.id}"

      expect(Comment.find_by(id: comment.id)).to be_nil
      expect(response).to redirect_to(user_path(user))
      expect(flash[:notice]).to eq("Comment was successfully deleted.")
    end
  end
end
