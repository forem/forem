class Internal::ReactionsController < Internal::ApplicationController
  def update
    @reaction = Reaction.find(params[:id])
    @reaction.update(status: params[:reaction][:status])
    Moderator::SinkArticles.call(@reaction.reactable_id) if confirmed_vomit_reaction?
    notify(:moderator, current_user, __method__) { cleanse_for_audit(params.dup) }
    redirect_to "/internal/reports"
  end

  private

  def confirmed_vomit_reaction?
    @reaction.reactable_type == "User" && @reaction.status == "confirmed" && @reaction.category == "vomit"
  end
end
