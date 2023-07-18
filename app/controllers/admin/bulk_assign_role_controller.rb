module Admin
  class BulkAssignRoleController < Admin::ApplicationController
    layout "admin"
    include Admin::UsersHelper

    def assign_role
      if permitted_params[:role].blank?
        raise ArgumentError,
              I18n.t("admin.bulk_assign_role_controller.role_blank")
      end

      role = permitted_params[:role]
      usernames = permitted_params[:usernames].downcase.split(/\s*,\s*/)
      note = permitted_params[:note_for_current_role].presence
      note ||= I18n.t("admin.bulk_assign_role_controller.role_assigment", role: role)

      begin
        usernames.each do |username|
          user = User.find_by(username: username)
          user_action_status = user_action_status(user, role)
          if user
            Moderator::ManageActivityAndRoles.handle_user_roles(
              admin: current_user,
              user: user,
              user_params: { user_status: role, note_for_current_role: note },
            )
          end

          AuditLog.create(
            category: "admin.bulk_assign_role.add_role",
            user: current_user,
            roles: current_user.roles_name,
            slug: "bulk_assign_role",
            data: {
              role: role,
              username: username,
              user_action_status: user_action_status
            },
          )
        end
        flash[:success] = I18n.t("admin.bulk_assign_role_controller.success_message")
      rescue StandardError => e
        flash[:danger] = e.message
      end
      redirect_to admin_bulk_assign_role_index_path
    rescue ArgumentError => e
      flash[:danger] = e.message
      redirect_to admin_bulk_assign_role_index_path
    end

    private

    # We need to override this method from Admin::ApplicationController since
    # there is no resource to authorize.
    def authorization_resource; end

    def user_action_status(user, role)
      if user
        return "user_already_has_the_role" if user_status(user) == role

        return "role_applied_successfully"
      end
      "user_not_found"
    end

    def permitted_params
      params.permit(:usernames, :role, :note_for_current_role)
    end
  end
end
