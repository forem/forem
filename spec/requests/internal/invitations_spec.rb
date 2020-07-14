require "rails_helper"

RSpec.describe "/internal/invitations", type: :request do
  let(:user) { create(:user) }
  let(:admin) { create(:user, :super_admin) }

  before do
    sign_in(admin)
  end

  describe "GETS /internal/invitations" do
    it "renders to appropriate page" do
      user.update_column(:registered, false)
      get "/internal/invitations"
      expect(response.body).to include(user.username)
    end
  end

  describe "GETS /internal/invitations/new" do
    it "renders to appropriate page" do
      get "/internal/invitations/new"
      expect(response.body).to include("Email:")
    end
  end

  describe "POST /internal/invitations" do
    it "creates new invitation" do
      post "/internal/invitations",
           params: { user: { email: "hey#{rand(1000)}@email.co", name: "Roger #{rand(1000)}" } }
      expect(User.last.registered).to be false
    end
  end
end
