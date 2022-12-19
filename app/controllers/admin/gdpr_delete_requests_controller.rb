module Admin
  class GDPRDeleteRequestsController < Admin::ApplicationController
    layout "admin"

    def index
      @gdpr_delete_requests = Admin::GDPRDeleteRequestsQuery.call(search: params[:search]).page(params[:page]).per(50)
    end

    def destroy
      @gdpr_delete_request = ::GDPRDeleteRequest.find(params[:id])

      begin
        @gdpr_delete_request.destroy

        AuditLog.create(
          user: current_user,
          category: "admin.gdpr_delete.confirm",
          roles: current_user.roles_name,
          slug: "gdpr_delete_confirm",
          data: {
            user_id: @gdpr_delete_request.user_id
          },
        )
        flash[:success] = I18n.t("admin.gdpr_delete_requests_controller.deleted")
      rescue StandardError => e
        flash[:danger] = e.message
      end

      redirect_to admin_gdpr_delete_requests_path
    end
  end
end
