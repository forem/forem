module Api
  module V0
    class UsersController < ApplicationController
      def index
        unless user_signed_in?
          @users = []
          return
        end
        if params[:state] == "follow_suggestions"
          @users = UserFollowSuggester.new(current_user).suggestions
        end
      end
    end
  end
end
