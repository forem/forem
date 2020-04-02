module Api
  module V0
    class ReactionsController < ApiController
      skip_before_action :verify_authenticity_token

      def create
        reaction_user = load_reaction_user
        unless reaction_user
          render json: { error: "invalid user" }, status: :unprocessable_entity
          return
        end

        @reaction = Reaction.create!(
          user: reaction_user,
          reactable_id: reaction_params[:reactable_id],
          reactable_type: reaction_params[:reactable_type],
          category: reaction_params[:category] || "like",
        )

        delete_reactable_cache(reaction_params[:reactable_id], reaction_params[:reactable_type])

        Notification.send_reaction_notification(@reaction, @reaction.reactable.user)
        Notification.send_reaction_notification(@reaction, @reaction.reactable.organization) if org_article?(@reaction)

        render json: { reaction: @reaction.to_json }
      end

      private

      def load_reaction_user
        user = User.find_by!(secret: params[:key])
        user = nil unless user.has_role?(:super_admin)
        user
      end

      def delete_reactable_cache(reactable_id, reactable_type)
        key = "count_for_reactable-#{reactable_type}-#{reactable_id}"
        Rails.cache.delete(key)
      end

      def reaction_params
        params.permit(:reactable_id, :reactable_type, :category)
      end

      def org_article?(reaction)
        reaction.reactable.is_a?(Article) && reaction.reactable.organization
      end
    end
  end
end
