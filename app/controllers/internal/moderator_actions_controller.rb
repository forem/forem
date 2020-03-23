class Internal::ModeratorActionsController < Internal::ApplicationController
  layout "internal"

  def index
    @q = AuditLog.
      includes(:user).
      where(category: "moderator.audit.log").
      order("created_at DESC").
      ransack(params[:q])
    @moderator_actions = @q.result.page(params[:page] || 1).per(50)
  end
end
