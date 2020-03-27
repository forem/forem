require "rails_helper"

RSpec.describe "/internal/moderator_reactions", type: :request do
  context "when the user is not an admin" do
    let(:user) { create(:user) }

    before do
      sign_in user
    end

    it "blocks the request" do
      expect do
        get "/internal/moderator_actions"
      end.to raise_error(Pundit::NotAuthorizedError)
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
        get "/internal/moderator_actions"
      end.not_to raise_error
    end

    describe "GETS /internal/moderator_actions" do
      it "renders to appropriate page" do
        get "/internal/moderator_actions"
        expect(response.body).to include(admin.username)
        expect(response.body).to include(audit_log.id.to_s)
      end
    end
  end
end
