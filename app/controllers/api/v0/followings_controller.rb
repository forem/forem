module Api
  module V0
    class FollowingsController < ApiController
      before_action :authenticate_with_api_key_or_current_user!
      before_action -> { limit_per_page(default: 80, max: 1000) }

      def users
        @follows = current_user.
          follows_by_type("User").
          order("created_at DESC").
          includes(:followable).
          page(params[:page]).
          per(@follows_limit)
      end

      def tags
        @followed_tags = current_user.
          follows_by_type("ActsAsTaggableOn::Tag").
          order("points DESC").
          includes(:followable).
          page(params[:page]).
          per(@follows_limit)
      end

      def organizations
        @followed_organizations = current_user.
          follows_by_type("Organization").
          order("created_at DESC").
          includes(:followable).
          page(params[:page]).
          per(@follows_limit)
      end

      def podcasts
        @followed_podcasts = current_user.
          follows_by_type("Podcast").
          order("created_at DESC").
          includes(:followable).
          page(params[:page]).
          per(@follows_limit)
      end

      private

      def limit_per_page(default:, max:)
        per_page = (params[:per_page] || default).to_i
        @follows_limit = [per_page, max].min
      end
    end
  end
end
