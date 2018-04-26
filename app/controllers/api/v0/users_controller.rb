module Api
  module V0
    class UsersController < ApplicationController
      def index
        if !user_signed_in? || less_than_one_day_old?(current_user)
          usernames = ["ben", "jess", "peter", "maestromac", "andy", "lianafelt"]
          @users = User.where(username: usernames)
          return
        end
        if params[:state] == "follow_suggestions"
          @users = UserFollowSuggester.new(current_user).suggestions
        elsif params[:state] == "sidebar_suggestions"
          given_tag = params[:tag]
          @users = UserFollowSuggester.new(current_user).sidebar_suggestions(given_tag)
        end
      end

      def less_than_one_day_old?(user)
        range = (Time.now.beginning_of_day - 1.day)..(Time.now)
        user_identity_age = user.github_created_at ||
          user.twitter_created_at ||
          Time.parse(user.identity.first.auth_data_dump.extra.raw_info.created_at)
        # last one is a fallback in case both are nil
        range.cover? user_identity_age
      end
    end
  end
end
