module Api
  module V0
    class FollowersController < ApiController
      before_action :authenticate_with_api_key_or_current_user!
      before_action -> { limit_per_page(default: 80, max: 1000) }

      def organizations
        @follows = Follow.
          where(followable_id: @user.organization_id, followable_type: "Organization").
          includes(:follower).
          select(ATTRIBUTES_FOR_SERIALIZATION).
          order("created_at DESC").
          page(params[:page]).
          per(@follows_limit)
      end

      def users
        @follows = Follow.
          where(followable_id: @user.id, followable_type: "User").
          includes(:follower).
          select(ATTRIBUTES_FOR_SERIALIZATION).
          order("created_at DESC").
          page(params[:page]).
          per(@follows_limit)
      end

      ATTRIBUTES_FOR_SERIALIZATION = %i[id follower_id follower_type].freeze
      private_constant :ATTRIBUTES_FOR_SERIALIZATION

      private

      def limit_per_page(default:, max:)
        per_page = (params[:per_page] || default).to_i
        @follows_limit = [per_page, max].min
      end
    end
  end
end
