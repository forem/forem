require "rails_helper"

RSpec.describe "Comments", type: :request do
  let(:user) { create(:user) }
  let(:article) { create(:article, user_id: user.id) }
  let(:podcast) { create(:podcast) }
  let(:podcast_episode) { create(:podcast_episode, podcast_id: podcast.id) }
  let(:comment) do
    create(:comment,
           commentable_id: article.id,
           commentable_type: "Article",
           user_id: user.id)
  end
  let(:podcast_comment) do
    create(:comment,
           commentable_id: podcast_episode.id,
           commentable_type: "PodcastEpisode",
           user_id: user.id)
  end

  describe "GET comment index" do
    it "returns 200" do
      get comment.path
      expect(response).to have_http_status(200)
    end

    it "displays a comment" do
      get comment.path
      expect(response.body).to include(comment.processed_html)
    end

    context "when the comment is for a podcast's episode" do
      it "works" do
        get podcast_comment.path
        expect(response).to have_http_status(200)
      end
    end
  end

  describe "GET /:username/:slug/comments/:id_code/edit" do
    context "when not logged-in" do
      it "returns not_found " do
        expect do
          get "/#{user.username}/#{article.slug}/comments/#{comment.id_code_generated}/edit"
        end.to raise_error(ActionController::RoutingError)
      end
    end

    context "when logged-in" do
      before do
        login_as user
      end

      it "returns 200" do
        get "/#{user.username}/#{article.slug}/comments/#{comment.id_code_generated}/edit"
        expect(response).to have_http_status(200)
      end

      it "returns the comment" do
        get "/#{user.username}/#{article.slug}/comments/#{comment.id_code_generated}/edit"
        expect(response.body).to include CGI.escapeHTML(comment.body_markdown)
      end
    end
  end
end
