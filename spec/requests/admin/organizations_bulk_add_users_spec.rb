require "rails_helper"

RSpec.describe "Admin Bulk Add Users to Organization" do
  let(:admin) { create(:user, :super_admin) }
  let(:regular_user) { create(:user) }
  let(:organization) { create(:organization) }
  let(:user1) { create(:user, username: "dev_alice") }
  let(:user2) { create(:user, username: "dev_bob") }

  describe "POST /admin/content_manager/organizations/:id/bulk_add_users" do
    it "denies access to non-admin users" do
      sign_in(regular_user)
      expect do
        post bulk_add_users_admin_organization_path(organization), params: { usernames: user1.username }
      end.to raise_error(Pundit::NotAuthorizedError)
    end

    context "when authorized as admin" do
      before { sign_in(admin) }

      it "successfully bulk adds users to the organization and redirects", :aggregate_failures do
        expect do
          post bulk_add_users_admin_organization_path(organization), params: {
            usernames: "@#{user1.username},  #{user2.username} ",
            role: "member"
          }
        end.to change { organization.organization_memberships.count }.by(2)

        expect(response).to redirect_to(admin_organization_path(organization))
        expect(flash[:notice]).to include(user1.username)
        expect(flash[:notice]).to include(user2.username)

        expect(organization.organization_memberships.pluck(:user_id)).to contain_exactly(user1.id, user2.id)
      end

      it "allows specifying admin role for new members", :aggregate_failures do
        post bulk_add_users_admin_organization_path(organization), params: {
          usernames: "@#{user1.username}",
          role: "admin"
        }

        membership = organization.organization_memberships.find_by(user_id: user1.id)
        expect(membership.type_of_user).to eq("admin")
      end

      it "handles empty input gracefully", :aggregate_failures do
        expect do
          post bulk_add_users_admin_organization_path(organization), params: { usernames: "  " }
        end.not_to change { organization.organization_memberships.count }

        expect(response).to redirect_to(admin_organization_path(organization))
        expect(flash[:error]).to be_present
      end

      it "reports already-members and non-existent users", :aggregate_failures do
        create(:organization_membership, organization: organization, user: user1, type_of_user: "member")

        expect do
          post bulk_add_users_admin_organization_path(organization), params: {
            usernames: "@#{user1.username}, #{user2.username}, unknown_user_999",
            role: "member"
          }
        end.to change { organization.organization_memberships.count }.by(1)

        expect(response).to redirect_to(admin_organization_path(organization))
        expect(flash[:notice]).to include(user2.username)
        expect(flash[:notice]).to include(user1.username)
        expect(flash[:notice]).to include("unknown_user_999")
      end

      it "creates an audit log and admin note on the organization", :aggregate_failures do
        Audit::Subscribe.listen :moderator
        expect do
          post bulk_add_users_admin_organization_path(organization), params: {
            usernames: "@#{user1.username}, #{user2.username}",
            role: "member"
          }
        end.to change(AuditLog, :count).by(1)
          .and change(Note, :count).by(1)

        audit_log = AuditLog.last
        expect(audit_log.category).to eq(AuditLog::MODERATOR_AUDIT_LOG_CATEGORY)
        expect(audit_log.user_id).to eq(admin.id)
        expect(audit_log.data["action"]).to eq("bulk_add_users")
        expect(audit_log.data["target_organization_id"]).to eq(organization.id)
        expect(audit_log.data["added_users"]).to contain_exactly(user1.username, user2.username)

        note = Note.last
        expect(note.noteable).to eq(organization)
        expect(note.author_id).to eq(admin.id)
        expect(note.content).to include("Bulk added 2 user(s) as member: #{user1.username}, #{user2.username}")
      ensure
        Audit::Subscribe.forget :moderator
      end
    end
  end
end
