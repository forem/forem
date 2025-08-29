require "rails_helper"

RSpec.describe "Admin::CommunityBots", type: :request do
  let(:admin_user) { create(:user, :super_admin) }
  let(:subforem) { create(:subforem, domain: "test.com") }

  before do
    sign_in admin_user
  end

  describe "GET /admin/customization/subforems/:subforem_id/community_bots" do
    it "returns a successful response" do
      get admin_subforem_community_bots_path(subforem)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /admin/customization/subforems/:subforem_id/community_bots/new" do
    it "returns a successful response" do
      get new_admin_subforem_community_bot_path(subforem)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /admin/customization/subforems/:subforem_id/community_bots" do
    it "creates a new community bot" do
      expect do
        post admin_subforem_community_bots_path(subforem), params: { user: { name: "Test Bot" } }
      end.to change(User, :count).by(1)

      expect(response).to redirect_to(admin_subforem_community_bots_path(subforem))
      expect(flash[:success]).to include("created successfully")
    end
  end

  describe "GET /admin/customization/subforems/:subforem_id/community_bots/:id" do
    let(:bot_user) { create(:user, type_of: :community_bot, onboarding_subforem_id: subforem.id) }

    it "returns a successful response" do
      get admin_subforem_community_bot_path(subforem, bot_user)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "DELETE /admin/customization/subforems/:subforem_id/community_bots/:id" do
    let!(:bot_user) { create(:user, type_of: :community_bot, onboarding_subforem_id: subforem.id) }

    it "deletes the community bot" do
      expect do
        delete admin_subforem_community_bot_path(subforem, bot_user)
      end.to change(User, :count).by(-1)

      expect(response).to redirect_to(admin_subforem_community_bots_path(subforem))
      expect(flash[:success]).to include("deleted successfully")
    end
  end
end


