module Api
  module V0
    class UsersController < ApiController
      before_action :authenticate!, only: %i[me]
      before_action -> { doorkeeper_authorize! :public }, only: :me, if: -> { doorkeeper_token }

      def index
        if !user_signed_in? || less_than_one_day_old?(current_user)
          usernames = %w[ben jess peter maestromac andy liana]
          @users = User.where(username: usernames)
          return
        end

        @users = if params[:state] == "follow_suggestions"
                   Suggester::Users::Recent.new(
                     current_user,
                     attributes_to_select: INDEX_ATTRIBUTES_FOR_SERIALIZATION,
                   ).suggest
                 elsif params[:state] == "sidebar_suggestions"
                   Suggester::Users::Sidebar.new(current_user, params[:tag]).suggest.sample(3)
                 else
                   User.none
                 end
      end

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

      INDEX_ATTRIBUTES_FOR_SERIALIZATION = %i[id name username summary].freeze
      private_constant :INDEX_ATTRIBUTES_FOR_SERIALIZATION

      SHOW_ATTRIBUTES_FOR_SERIALIZATION = %i[
        id username name summary twitter_username github_username website_url
        location created_at
      ].freeze
      private_constant :SHOW_ATTRIBUTES_FOR_SERIALIZATION

      private

      def less_than_one_day_old?(user)
        range = 1.day.ago.beginning_of_day..Time.current
        user_identity_age = user.github_created_at || user.twitter_created_at || 8.days.ago
        # last one is a fallback in case both are nil
        range.cover? user_identity_age
      end
    end
  end
end
