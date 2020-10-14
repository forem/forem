require "rails_helper"

RSpec.describe "/admin/invitations", type: :request do
  let(:user) { create(:user) }
  let(:admin) { create(:user, :super_admin) }

  before do
    sign_in(admin)
  end

  describe "GET /admin/invitations" do
    it "renders to appropriate page" do
      user.update_column(:registered, false)
      get "/admin/invitations"
      expect(response.body).to include(user.username)
    end
  end

  describe "GET /admin/invitations/new" do
    it "renders to appropriate page" do
      get "/admin/invitations/new"
      expect(response.body).to include("Email:")
    end
  end

  describe "POST /admin/invitations" do
    it "creates new invitation" do
      post "/admin/invitations",
           params: { user: { email: "hey#{rand(1000)}@email.co", name: "Roger #{rand(1000)}" } }
      expect(User.last.registered).to be false
    end
  end
end
