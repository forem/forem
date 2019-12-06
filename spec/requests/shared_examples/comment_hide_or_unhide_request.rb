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

    it "returns a proper JSON response" do
      expect(JSON.parse(response.body)).to eq("hidden" => args[:hidden])
    end

    it "returns 200 on a good request" do
      expect(response).to have_http_status(:ok)
    end
  end
end
