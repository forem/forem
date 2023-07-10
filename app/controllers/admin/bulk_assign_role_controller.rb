module Admin
  class BulkAssignRoleController < Admin::ApplicationController
    layout "admin"

    def assign_role
      if permitted_params[:role].blank?
        raise ArgumentError,
              I18n.t("admin.bulk_assign_role_controller.award")
      end

      role = permitted_params[:role]
      usernames = permitted_params[:usernames].downcase.split(/\s*,\s*/)
      note = permitted_params[:note_for_current_role].presence || I18n.t("admin.bulk_assign_role_controller.congrats")

      begin
        usernames.each do |username|
          user = User.find_by(username: username.strip.downcase)
          next unless user

          Moderator::ManageActivityAndRoles.handle_user_roles(
            admin: current_user,
            user: user,
            user_params: { user_status: role, note_for_current_role: note },
          )
        end

        flash[:success] = I18n.t("admin.bulk_assign_role_controller.success_message")
        redirect_to admin_bulk_assign_role_index_path
      rescue StandardError => e
        flash[:danger] = e.message
        redirect_to admin_bulk_assign_role_index_path
      end
    end

    private

    def permitted_params
      params.permit(:usernames, :role, :note_for_current_role)
    end
  end
end
