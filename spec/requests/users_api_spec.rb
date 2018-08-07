require "rails_helper"

RSpec.describe "ArticlesApi", type: :request do
  let(:user) { create(:user) }
  let(:tag) { create(:tag) }

  describe "GET /api/users" do
    it "returns user objects" do
      other_user = create(:user, tag_list: tag.name)
      user.follow(tag)
      sign_in user
      get "/api/users?state=follow_suggestions"
      expect(response.body).to include(other_user.name)
    end
  end

  describe "GET /api/users/:id" do
    it "returns user show object" do
      get "/api/users/#{user.id}"
      expect(response.body).to include(user.name)
    end
  end
end
