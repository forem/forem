module Admin
  class ReactionsController < Admin::ApplicationController
    after_action only: [:update] do
      Audit::Logger.log(:moderator, current_user, params.dup)
    end

    def update
      @reaction = Reaction.find(params[:id])
      if @reaction.update(status: params[:status])
        @reaction.reactable.touch
        Moderator::SinkArticles.call(@reaction.reactable_id) if vomit_user_reaction?
        render json: { outcome: "Success" }
      else
        render json: { error: @reaction.errors_as_sentence }, status: :unprocessable_entity
      end
    end

    private

    def vomit_user_reaction?
      @reaction.reactable_type == "User" && @reaction.category == "vomit"
    end
  end
end
