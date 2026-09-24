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
      authorize @reaction, support_admin_policy_query, policy_class: ReactionPolicy
    end

    # Invalidating a flag is all a support admin needs in order to un-hide a
    # downvoted comment. Any other status change falls through to a policy
    # query only full admins satisfy.
    def support_admin_policy_query
      params[:status] == "invalid" ? :admin_invalidate? : :admin_update?
    end

    def vomit_user_reaction?
      @reaction.reactable_type == "User" && @reaction.category == "vomit"
    end
  end
end
