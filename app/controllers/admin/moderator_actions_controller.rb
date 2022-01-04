module Admin
  class ModeratorActionsController < Admin::ApplicationController
    layout "admin"

    def index
      @q = AuditLog
        .includes(:user)
        .where(category: AuditLog::MODERATOR_AUDIT_LOG_CATEGORY)
        .order(created_at: :desc)
        .ransack(params[:q])
      @moderator_actions = @q.result.page(params[:page] || 1).per(25)
    end
  end
end
