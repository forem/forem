module Api
  module V0
    class UsersController < ApiController
      before_action :authenticate!, only: %i[me]
      before_action -> { doorkeeper_authorize! :public }, only: :me, if: -> { doorkeeper_token }

      def show
        relation = User.select(SHOW_ATTRIBUTES_FOR_SERIALIZATION)

        @user = if params[:id] == "by_username"
                  relation.find_by!(username: params[:url])
                else
                  relation.find(params[:id])
                end
      end

      def me
        render :show
      end

      SHOW_ATTRIBUTES_FOR_SERIALIZATION = %i[
        id username name summary twitter_username github_username website_url
        location created_at profile_image
      ].freeze
      private_constant :SHOW_ATTRIBUTES_FOR_SERIALIZATION
    end
  end
end
