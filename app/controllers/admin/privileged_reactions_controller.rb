module Admin
  class PrivilegedReactionsController < Admin::ApplicationController
    layout "admin"

    PRIVILEGED_REACTION_CATEGORIES = %i[thumbsup thumbsdown vomit].freeze

    def index
      @q = Reaction
        .includes(:user,
                  :reactable)
        .where("category IN (?)", PRIVILEGED_REACTION_CATEGORIES)
        .order("reactions.created_at" => :desc)
        .ransack(params[:q])
      @privileged_reactions = @q.result.page(params[:page] || 1).per(25)
    end
  end
end
