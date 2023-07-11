module Admin
  class BulkAssignRoleController < Admin::ApplicationController
    layout "admin"

    def assign_role
      if permitted_params[:role].blank?
        raise ArgumentError,
              I18n.t("admin.bulk_assign_role_controller.role_blank")
      end

      role = permitted_params[:role]
      usernames = permitted_params[:usernames].downcase.split(/\s*,\s*/)
      note = permitted_params[:note_for_current_role].presence || I18n.t("admin.bulk_assign_role_controller.congrats")

      begin
        usernames.each do |username|
          user = User.find_by(username: username.strip.downcase)
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
              user_name: username,
              user_action_status: user_action_status
            },
          )
        end

        flash[:success] = I18n.t("admin.bulk_assign_role_controller.success_message")
        redirect_to admin_bulk_assign_role_index_path
      rescue StandardError => e
        flash[:danger] = e.message
        redirect_to admin_bulk_assign_role_index_path
      end
    rescue ArgumentError => e
      flash[:danger] = e.message
      redirect_to admin_bulk_assign_role_index_path
    end

    private

    def user_action_status(user, role)
      if user
        return "user_already_had_the_role" if role_already_added(user, role)

        return "role_was_applied_successfully"
      end
      "user_not_found"
    end

    def role_already_added(user, role)
      case role
      when "Suspended"
        user.suspended?
      when "Warned"
        user.warned?
      when "Comment Suspended"
        user.comment_suspended?
      when "Trusted"
        user.trusted?
      when "Good standing"
        user.good_standing?
      else
        false
      end
    end

    def permitted_params
      params.permit(:usernames, :role, :note_for_current_role)
    end
  end
end
