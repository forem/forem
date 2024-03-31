RSpec.shared_examples "PATCH /comments/:comment_id/hide or unhide" do |args|
  let(:commentable_author) { create(:user) }
  let(:article) { create(:article, user: commentable_author) }
  let(:parent_comment) { create(:comment, commentable: article, user: commentable_author) }

  it "returns 401 if user is not logged in" do
    patch "/comments/1/#{args[:path]}", headers: { HTTP_ACCEPT: "application/json" }
    expect(response).to have_http_status(:unauthorized)
  end

  context "when logged in as a random commenter" do
    before { sign_in user }

    it "returns unauthorized" do
      expect do
        patch "/comments/#{parent_comment.id}/#{args[:path]}", headers: { HTTP_ACCEPT: "application/json" }
      end.to raise_error(Pundit::NotAuthorizedError)
    end
  end

  context "when logged in as the commentable author" do
    before do
      sign_in commentable_author
      patch "/comments/#{parent_comment.id}/#{args[:path]}", headers: { HTTP_ACCEPT: "application/json" }
    end

    it "sets hidden_by_commentable_user appropriately" do
      parent_comment.reload
      expect(parent_comment.hidden_by_commentable_user).to eq(args[:path] == "hide")
    end

    it "marks article as having hidden comments" do
      expect(article.reload.any_comments_hidden).to eq(args[:path] == "hide")
    end

    it "returns a proper JSON response" do
      expect(response.parsed_body).to eq("hidden" => args[:hidden])
    end

    it "returns 200 on a good request" do
      expect(response).to have_http_status(:ok)
    end

    it "displays having hidden comments if some unhidden" do
      sign_in commentable_author
      second_comment = create(:comment, commentable: article, user: commentable_author)
      third_comment = create(:comment, commentable: article, user: commentable_author)
      patch "/comments/#{parent_comment.id}/hide", headers: { HTTP_ACCEPT: "application/json" }
      patch "/comments/#{second_comment.id}/hide", headers: { HTTP_ACCEPT: "application/json" }
      patch "/comments/#{third_comment.id}/hide", headers: { HTTP_ACCEPT: "application/json" }
      patch "/comments/#{second_comment.id}/unhide", headers: { HTTP_ACCEPT: "application/json" }
      expect(article.reload.any_comments_hidden).to be(true)
    end

    it "displays not having hidden comments if all unhidden" do
      sign_in commentable_author
      second_comment = create(:comment, commentable: article, user: commentable_author)
      third_comment = create(:comment, commentable: article, user: commentable_author)
      patch "/comments/#{parent_comment.id}/hide", headers: { HTTP_ACCEPT: "application/json" }
      patch "/comments/#{second_comment.id}/hide", headers: { HTTP_ACCEPT: "application/json" }
      patch "/comments/#{third_comment.id}/hide", headers: { HTTP_ACCEPT: "application/json" }
      patch "/comments/#{parent_comment.id}/unhide", headers: { HTTP_ACCEPT: "application/json" }
      patch "/comments/#{second_comment.id}/unhide", headers: { HTTP_ACCEPT: "application/json" }
      patch "/comments/#{third_comment.id}/unhide", headers: { HTTP_ACCEPT: "application/json" }
      expect(article.reload.any_comments_hidden).to be(false)
    end
  end
end
