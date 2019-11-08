module Api
  module V0
    class ReactionsController < ApplicationController
      skip_before_action :verify_authenticity_token
      def create
        @user = valid_user
        unless @user
          render json: { message: "invalid_user" }, status: :unprocessable_entity
          return
        end
        RedisRailsCache.delete "count_for_reactable-#{params[:reactable_type]}-#{params[:reactable_id]}"
        @reaction = Reaction.create(
          user_id: @user.id,
          reactable_id: params[:reactable_id],
          reactable_type: params[:reactable_type],
          category: params[:category] || "like",
        )
        Notification.send_reaction_notification(@reaction, @reaction.reactable.user)
        Notification.send_reaction_notification(@reaction, @reaction.reactable.organization) if organization_article?(@reaction)
        render json: { reaction: @reaction.to_json }
      end

      def onboarding
        verify_authenticity_token
        reactable_ids = JSON.parse(params[:articles]).map { |article| article["id"] }
        reactable_ids.each do |article_id|
          Reactions::CreateJob.perform_later(
            user_id: current_user.id,
            reactable_id: article_id,
            reactable_type: "Article",
            category: "readinglist",
          )
        end
      end

      private

      def valid_user
        user = User.find_by(secret: params[:key])
        user = nil unless user.has_role?(:super_admin)
        user
      end

      def organization_article?(reaction)
        reaction.reactable_type == "Article" && reaction.reactable.organization_id
      end
    end
  end
end
