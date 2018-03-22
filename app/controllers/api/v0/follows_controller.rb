module Api
  module V0
    class FollowsController < ApplicationController
      def create
        return unless user_signed_in?
        users = JSON.parse(params[:users])
        users.each do |user_hash|
          followable = User.find(user_hash['id'])
          current_user.delay.follow(followable)
        end
        render json: { outcome: "followed 50 users" }
      end
    end
  end
end