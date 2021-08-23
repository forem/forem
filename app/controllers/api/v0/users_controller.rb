module Api
  module V0
    class UsersController < ApiController
      before_action :authenticate!, only: %i[me]
      before_action -> { doorkeeper_authorize! :public }, only: :me, if: -> { doorkeeper_token }

      SHOW_ATTRIBUTES_FOR_SERIALIZATION = %i[
        id username name summary twitter_username github_username website_url
        location created_at profile_image registered
      ].freeze

      def show
        relation = User.joins(:profile).select(SHOW_ATTRIBUTES_FOR_SERIALIZATION)

        @user = if params[:id] == "by_username"
                  relation.find_by!(username: params[:url])
                else
                  relation.find(params[:id])
                end
        not_found unless @user.registered
      end

      def me
        render :show
      end
    end
  end
end
