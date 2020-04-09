require "rails_helper"

RSpec.describe "/internal/moderator_reactions", type: :request do
  context "when the user is not an admin" do
    let(:user) { create(:user) }

    before do
      sign_in user
    end

    it "blocks the request" do
      expect do
        get internal_moderator_actions_path
      end.to raise_error(Pundit::NotAuthorizedError)
    end
  end

  context "when the user is a single resource admin" do
    let(:single_resource_admin) { create(:user, :single_resource_admin, resource: ModeratorAction) }

    it "renders with status 200" do
      sign_in single_resource_admin
      get internal_moderator_actions_path
      expect(response.status).to eq 200
    end
  end

  context "when the user is an admin" do
    let(:admin)      { create(:user, :admin) }
    let!(:audit_log) { create(:audit_log, category: "moderator.audit.log", user_id: admin.id, roles: admin.roles.pluck(:name)) }

    before do
      sign_in admin
    end

    it "does not block the request" do
      expect do
        get internal_moderator_actions_path
      end.not_to raise_error
    end

    describe "GETS /internal/moderator_actions" do
      it "renders to appropriate page" do
        get internal_moderator_actions_path
        expect(response.body).to include(admin.username)
        expect(response.body).to include(audit_log.id.to_s)
      end
    end
  end
end
