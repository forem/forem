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

    it "does not create an invitation if a user with that email exists" do
      expect do
        post "/admin/invitations",
             params: { user: { email: admin.email, name: "Roger #{rand(1000)}" } }
      end.not_to change { User.all.count }
      expect(admin.reload.registered).to be true
      expect(flash[:error].present?).to be true
    end
  end

  describe "DELETE /admin/invitations" do
    let!(:invitation) { create(:user, registered: false) }

    before do
      sign_in admin
    end

    it "deletes the invitation" do
      expect do
        delete "/admin/invitations/#{invitation.id}"
      end.to change { User.all.count }.by(-1)
      expect(response.body).to redirect_to "/admin/invitations"
    end
  end
end
