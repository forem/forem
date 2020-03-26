class Internal::ReactionsController < Internal::ApplicationController
  after_action only: [:update] do
    Audit::Logger.log(:moderator, current_user, params.dup)
  end

  def update
    @reaction = Reaction.find(params[:id])
    @reaction.update(status: params[:reaction][:status])
    Moderator::SinkArticles.call(@reaction.reactable_id) if confirmed_vomit_reaction?
    redirect_to "/internal/reports"
  end

  private

  def confirmed_vomit_reaction?
    @reaction.reactable_type == "User" && @reaction.status == "confirmed" && @reaction.category == "vomit"
  end
end
