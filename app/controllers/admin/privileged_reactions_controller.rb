module Admin
  class PrivilegedReactionsController < Admin::ApplicationController
    layout "admin"

    def index
      @q = Reaction
        .includes(:user, :reactable)
        .privileged_category
        .order(created_at: :desc)
        .ransack(params[:q])
      @privileged_reactions = @q.result.page(params[:page] || 1).per(25)
    end
  end
end
