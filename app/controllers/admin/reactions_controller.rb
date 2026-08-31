module Admin
  class ReactionsController < Admin::ApplicationController
    after_action only: [:update] do
      Audit::Logger.log(:moderator, current_user, params.dup)
    end

    def update
      @reaction ||= Reaction.find(params[:id])

      if @reaction.update(status: params[:status])
        @reaction.reactable.touch
        Moderator::SinkArticles.call(@reaction.reactable_id) if vomit_user_reaction?
        render json: { outcome: "Success" }
      else
        render json: { error: @reaction.errors_as_sentence }, status: :unprocessable_entity
      end
    end

    private

    # Support admins may only moderate reactions on comments, so for them the
    # reaction is loaded up front and authorized against its reactable. Every
    # other role keeps the existing InternalPolicy check.
    def authorize_admin
      return super unless current_user&.support_admin?

      @reaction = Reaction.find(params[:id])
      authorize @reaction, :admin_update?, policy_class: ReactionPolicy
    end

    def vomit_user_reaction?
      @reaction.reactable_type == "User" && @reaction.category == "vomit"
    end
  end
end
