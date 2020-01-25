module Api
  module V0
    class ReactionsController < ApiController
      skip_before_action :verify_authenticity_token

      caches_action :articles,
                    cache_path: proc { |c| c.params.permit! },
                    expires_in: 5.minutes
      before_action -> { limit_per_page(default: 80, max: 1000) }

      def create
        @user = valid_user
        unless @user
          render json: { message: "invalid_user" }, status: :unprocessable_entity
          return
        end
        Rails.cache.delete "count_for_reactable-#{params[:reactable_type]}-#{params[:reactable_id]}"
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

      def articles
        user = User.find_by(username: params[:username])

        return unless user

        @stories = Article.
          joins(:reactions).
          where(reactions: { user_id: user.id, reactable_type: "Article", category: %w[like unicorn] }).
          order("published_at DESC").
          page(params[:page]).
          per(@reactions_limit).
          decorate.
          uniq
      end

      def onboarding
        verify_authenticity_token
        reactable_ids = JSON.parse(params[:articles]).map { |article| article["id"] }
        reactable_ids.each do |article_id|
          Reactions::CreateWorker.perform_async(current_user.id, article_id, "Article", "readinglist")
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

      def limit_per_page(default:, max:)
        per_page = (params[:per_page] || default).to_i
        @reactions_limit = [per_page, max].min
      end
    end
  end
end
