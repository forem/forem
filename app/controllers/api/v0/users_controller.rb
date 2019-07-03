module Api
  module V0
    class UsersController < ApplicationController
      def index
        if !user_signed_in? || less_than_one_day_old?(current_user)
          usernames = %w[ben jess peter maestromac andy liana]
          @users = User.where(username: usernames)
          return
        end
        if params[:state] == "follow_suggestions"
          @users = Suggester::Users::Recent.new(current_user).suggest
        elsif params[:state] == "sidebar_suggestions"
          given_tag = params[:tag]
          @users = Suggester::Users::Sidebar.new(current_user, given_tag).suggest.sample(3)
        end
      end

      def show
        @user = if params[:id] == "by_username"
                  User.find_by(username: params[:url])
                else
                  User.find(params[:id])
                end
      end

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
