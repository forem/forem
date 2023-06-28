module Api
  module V1
    class ReactionsController < ApiController
      before_action :authenticate!
      before_action :require_admin

      def create
        remove_count_cache_key

        result = ReactionHandler.create(params, current_user: current_user || @user)

        if result.success?
          render json: {
                   result: result.action,
                   category: result.category,
                   id: result.reaction.id,
                   reactable_id: result.reaction.reactable_id,
                   reactable_type: result.reaction.reactable_type
                 },
                 status: (result.action == "create" ? :created : :ok)
        else
          render json: { error: result.errors_as_sentence, status: 422 }, status: :unprocessable_entity
        end
      end

      def toggle
        remove_count_cache_key

        result = ReactionHandler.toggle(params, current_user: current_user || @user)

        if result.success?
          render json: {
            result: result.action,
            category: result.category,
            id: result.reaction.id,
            reactable_id: result.reaction.reactable_id,
            reactable_type: result.reaction.reactable_type
          }
        else
          render json: { error: result.errors_as_sentence, status: 422 }, status: :unprocessable_entity
        end
      end

      private

      # TODO: should this move to toggle service? refactor?
      def remove_count_cache_key
        return unless params[:reactable_type] == "Article"

        Rails.cache.delete "count_for_reactable-Article-#{params[:reactable_id]}"
      end

      def require_admin
        authorize :reaction, :api?
      end
    end
  end
end
