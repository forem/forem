class Internal::NegativeReactionsController < Internal::ApplicationController
  layout "internal"

  NEGATIVE_REACTION_CATEGORIES = %i[vomit thumbsdown].freeze

  def index
    @q = Reaction.
      includes(:user,
               :reactable).
      where("category IN (?)", NEGATIVE_REACTION_CATEGORIES).
      order("reactions.created_at DESC").
      ransack(params[:q])
    @negative_reactions = @q.result.page(params[:page] || 1).per(25)
  end
end
