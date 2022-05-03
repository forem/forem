module Admin
  class GdprDeleteRequestsController < Admin::ApplicationController
    layout "admin"

    def index
      @gdpr_delete_requests = ::GdprDeleteRequest.order(created_at: :desc).page(params[:page]).per(50)
    end

    def destroy
      @gdpr_delete_request = ::GdprDeleteRequest.find(params[:id])
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

      redirect_to admin_gdpr_delete_requests_path
    end
  end
end
