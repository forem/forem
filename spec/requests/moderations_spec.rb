require "rails_helper"

RSpec.describe "Moderations", type: :request, proper_status: true do
  let(:user) { create(:user) }
  let(:article) { create(:article, user: user) }
  let(:comment) do
    create(:comment,
           commentable_id: article.id,
           commentable_type: "Article",
           user: user)
  end

  context "when user is not trusted" do
    before do
      sign_in user
    end

    it "does not grant access article moderation" do
      get "/username/random-article/mod"
      expect(response).to have_http_status(404)
    end

    it "does not grant access to comment moderation" do
      get "/username/comment/1/mod"
      expect(response).to have_http_status(404)
    end
  end

  context "when user is trusted" do
    before do
      user.add_role :trusted
      sign_in user
    end

    it "grant acess to article moderation" do
      get article.path + "/mod"
      expect(response).to have_http_status(200)
    end

    it "grant acess to comment moderation" do
      get comment.path + "/mod"
      expect(response).to have_http_status(200)
    end
  end
end
