module Admin
  class ModeratorActionsController < Admin::ApplicationController
    layout "admin"

    def index
      @q = AuditLog
        .includes(:user)
        .where(category: "moderator.audit.log")
        .order(created_at: :desc)
        .ransack(params[:q])
      @moderator_actions = @q.result.page(params[:page] || 1).per(25)
    end
  end
end
