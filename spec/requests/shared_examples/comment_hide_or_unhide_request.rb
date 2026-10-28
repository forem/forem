RSpec.shared_examples "PATCH /comments/:comment_id/hide or unhide" do |args|
  let(:commentable_author) { create(:user) }
  let(:article) { create(:article, user: commentable_author, with_tags: false) }
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
    before { sign_in commentable_author }

    it "updates hidden_by_commentable_user, marks article, and returns 200 JSON response", :aggregate_failures do
      patch "/comments/#{parent_comment.id}/#{args[:path]}", headers: { HTTP_ACCEPT: "application/json" }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq("hidden" => args[:hidden])
      expect(parent_comment.reload.hidden_by_commentable_user).to eq(args[:path] == "hide")
      expect(article.reload.any_comments_hidden).to eq(args[:path] == "hide")
    end
  end
end
