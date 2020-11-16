require "rails_helper"

RSpec.describe "Collections", type: :request do
  let(:user) { create(:user) }
  let(:collection) { create(:collection, :with_articles, user: user) }

  describe "GET user collections index" do
    it "returns 200" do
      get "/#{user.username}/series"
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET user collection show" do
    it "returns 200" do
      get collection.path
      expect(response).to have_http_status(:ok)
    end
  end
end
