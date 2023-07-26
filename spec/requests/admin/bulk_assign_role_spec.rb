require "rails_helper"

RSpec.describe "Admin::BulkAssignRole" do
  let(:admin) { create(:user, :super_admin) }
  let(:user1) { create(:user) }
  let(:user2) { create(:user) }
  let(:user3) { create(:user) }
  let(:usernames_string) { "#{user1.username}, #{user2.username}, #{user3.username}" }
  let(:role) { "Trusted" }
  let(:note_for_current_role) { "Assigned Trusted role" }
  let(:extra_space_usernames_string) { "#{user1.username},  #{user2.username},  #{user3.username}" }
  let(:invalid_role) { "Invalid Role" }

  describe "POST /admin/member_manager/bulk_assign_role" do
    before do
      sign_in admin
    end

    it "adds trusted role successfully" do
      params = { usernames: usernames_string, role: role, note_for_current_role: note_for_current_role }
      post admin_bulk_assign_role_path, params: params

      expect(response).to redirect_to(admin_bulk_assign_role_index_path)
      expect(flash[:success]).to eq(I18n.t("admin.bulk_assign_role_controller.success_message"))

      expect(user1.roles.count).to eq(1)
      expect(user1.roles.last.name).to eq(role.downcase)

      expect(user2.roles.count).to eq(1)
      expect(user2.roles.last.name).to eq(role.downcase)

      expect(user3.roles.count).to eq(1)
      expect(user3.roles.last.name).to eq(role.downcase)
    end

    it "adds role with extra whitespace in usernames" do
      params = { usernames: extra_space_usernames_string, role: role, note_for_current_role: note_for_current_role }
      post admin_bulk_assign_role_path, params: params

      expect(user1.roles.count).to eq(1)
      expect(user1.roles.last.name).to eq(role.downcase)

      expect(user2.roles.count).to eq(1)
      expect(user2.roles.last.name).to eq(role.downcase)

      expect(user3.roles.count).to eq(1)
      expect(user3.roles.last.name).to eq(role.downcase)
    end

    it "shows error if role is blank" do
      params = { usernames: usernames_string, note_for_current_role: note_for_current_role }
      post admin_bulk_assign_role_path, params: params

      expect(response).to redirect_to(admin_bulk_assign_role_index_path)
      expect(flash[:danger]).to eq(I18n.t("admin.bulk_assign_role_controller.role_blank"))

      expect(user1.roles.count).to eq(0)
      expect(user2.roles.count).to eq(0)
      expect(user3.roles.count).to eq(0)
    end

    it "adds default note if user input is empty" do
      params = { usernames: usernames_string, role: role }
      post admin_bulk_assign_role_path, params: params

      expect(user1.notes.last.content).to eq(I18n.t("admin.bulk_assign_role_controller.role_assigment", role: role))
    end

    it "adds role to valid usernames only and creates user_not_found AuditLog" do
      invalid_username = "invalidusername"
      params = { usernames: "#{user1.username}, #{user2.username}, #{invalid_username}", role: role,
                 note_for_current_role: note_for_current_role }
      post admin_bulk_assign_role_path, params: params

      expect(user1.roles.count).to eq(1)
      expect(user1.roles.last.name).to eq(role.downcase)

      expect(user2.roles.count).to eq(1)
      expect(user2.roles.last.name).to eq(role.downcase)

      log = AuditLog.last
      expect(log.data["role"]).to eq(role)
      expect(log.data["username"]).to eq(invalid_username)
      expect(log.data["user_action_status"]).to eq("user_not_found")
    end

    it "adds successful AuditLog" do
      params = { usernames: usernames_string, role: role, note_for_current_role: note_for_current_role }
      post admin_bulk_assign_role_path, params: params

      logs = AuditLog.last(3)
      expect(logs[0].category).to eq("admin.bulk_assign_role.add_role")
      expect(logs[0].user).to eq(admin)

      expect(logs[0].data["username"]).to eq(user1.username)
      expect(logs[0].data["user_action_status"]).to eq("role_applied_successfully")

      expect(logs[1].data["username"]).to eq(user2.username)
      expect(logs[1].data["user_action_status"]).to eq("role_applied_successfully")

      expect(logs[2].data["username"]).to eq(user3.username)
      expect(logs[2].data["user_action_status"]).to eq("role_applied_successfully")
    end

    it "adds role already applied AuditLog" do
      params = { usernames: user1.username.to_s, role: role, note_for_current_role: note_for_current_role }
      post admin_bulk_assign_role_path, params: params

      # Adding the role again to trigger the "user_already_has_the_role" AuditLog.
      post admin_bulk_assign_role_path, params: params

      log = AuditLog.last
      expect(log.data["role"]).to eq(role)
      expect(log.data["username"]).to eq(user1.username)
      expect(log.data["user_action_status"]).to eq("user_already_has_the_role")
    end
  end
end
