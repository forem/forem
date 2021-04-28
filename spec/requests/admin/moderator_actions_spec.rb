require "rails_helper"

RSpec.describe "/admin/moderation/moderator_reactions", type: :request do
  context "when the user is not an admin" do
    let(:user) { create(:user) }

    before do
      sign_in user
    end

    it "blocks the request" do
      expect do
        get admin_moderator_actions_path
      end.to raise_error(Pundit::NotAuthorizedError)
    end
  end

  context "when the user is a single resource admin" do
    let(:single_resource_admin) do
      create(:user, :single_resource_admin, resource: ModeratorAction)
    end

    it "renders the page" do
      sign_in single_resource_admin

      get admin_moderator_actions_path
      expect(response).to have_http_status(:ok)
    end
  end

  context "when the user is an admin" do
    let(:admin) { create(:user, :admin) }

    before do
      sign_in admin
    end

    it "does not block the request" do
      get admin_moderator_actions_path
      expect(response).to have_http_status(:ok)
    end

    it "renders the page with a user's audit log" do
      audit_log = create(
        :audit_log,
        category: "moderator.audit.log",
        user: admin,
        roles: admin.roles.pluck(:name),
      )

      get admin_moderator_actions_path

      expect(response.body).to include(admin.username)
      expect(response.body).to include(audit_log.id.to_s)
    end

    it "renders the page with an audit log not belonging to a specific user" do
      audit_log = create(
        :audit_log,
        category: "moderator.audit.log",
        user: nil,
      )

      get admin_moderator_actions_path

      expect(response.body).not_to include(admin.username)
      expect(response.body).to include(audit_log.id.to_s)
    end
  end
end
