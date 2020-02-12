require "rails_helper"

RSpec.shared_examples "an elevated privilege required request" do |path|
  context "when not logged-in" do
    it "does not grant acesss", proper_status: true do
      get path
      expect(response).to have_http_status(:not_found)
    end

    it "raises Pundit::NotAuthorizedError internally" do
      expect { get path }.to raise_error(Pundit::NotAuthorizedError)
    end
  end

  context "when user is not trusted" do
    before { sign_in create(:user) }

    it "does not grant acesss", proper_status: true do
      get path
      expect(response).to have_http_status(:not_found)
    end

    it "internally raise Pundit::NotAuthorized internally" do
      expect { get path }.to raise_error(Pundit::NotAuthorizedError)
    end
  end
end

RSpec.describe "Moderations", type: :request do
  let(:user) { create(:user, :trusted) }
  let(:article) { create(:article) }
  let(:comment) { create(:comment, commentable: article) }
  let(:dev_account) { create(:user) }

  it_behaves_like "an elevated privilege required request", "/username/random-article/mod"
  it_behaves_like "an elevated privilege required request", "/username/comment/1/mod"

  context "when user is trusted" do
    before do
      sign_in user
      allow(User).to receive(:dev_account).and_return(dev_account)
    end

    it "grants access to comment moderation" do
      get comment.path + "/mod"
      expect(response).to have_http_status(:ok)
    end

    it "grant access to article moderation" do
      get article.path + "/mod"
      expect(response).to have_http_status(:ok)
    end

    it "grants access to /mod index" do
      create(:rating_vote, article: article, user: user)
      get "/mod"
      expect(response).to have_http_status(:ok)
    end

    it "grants access to /mod index with articles" do
      create(:article, published: true)
      get "/mod"
      expect(response.body).to include("We build the")
    end

    it "grants access to /mod/:tag index with articles" do
      create(:article, published: true)
      get "/mod/#{article.tags.first}"
      expect(response.body).to include("#" + article.tags.first.name.titleize)
    end

    it "returns not found for inapprpriate tags" do
      expect { get "/mod/dsdsdsweweedsdseweww" }.to raise_exception(ActiveRecord::RecordNotFound)
    end

    it "renders not_found when an article can't be found" do
      expect { get "/#{user.username}/dsdsdsweweedsdseweww/mod/" }.to raise_exception(ActiveRecord::RecordNotFound)
    end
  end
end
