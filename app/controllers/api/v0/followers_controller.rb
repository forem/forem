module Api
  module V0
    class FollowersController < ApiController
      before_action :authenticate_with_api_key_or_current_user!
      before_action -> { limit_per_page(default: 80, max: 1000) }

      def organizations
        @follows = Follow.followable_organization(@user.organization_ids).
          includes(:follower).
          select(ORGANIZATIONS_ATTRIBUTES_FOR_SERIALIZATION).
          order("created_at DESC").
          page(params[:page]).
          per(@follows_limit)
      end

      def users
        @follows = Follow.followable_user(@user.id).
          includes(:follower).
          select(USERS_ATTRIBUTES_FOR_SERIALIZATION).
          order("created_at DESC").
          page(params[:page]).
          per(@follows_limit)
      end

      ORGANIZATIONS_ATTRIBUTES_FOR_SERIALIZATION = %i[id follower_id follower_type followable_id].freeze
      private_constant :ORGANIZATIONS_ATTRIBUTES_FOR_SERIALIZATION

      USERS_ATTRIBUTES_FOR_SERIALIZATION = %i[id follower_id follower_type].freeze
      private_constant :USERS_ATTRIBUTES_FOR_SERIALIZATION

      private

      def limit_per_page(default:, max:)
        per_page = (params[:per_page] || default).to_i
        @follows_limit = [per_page, max].min
      end
    end
  end
end
