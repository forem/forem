module Api
  module V0
    class FollowsController < ApplicationController
      def create
        return unless user_signed_in?

        user_ids = params[:users].map { |h| h["id"] }
        users = User.where(id: user_ids)
        users.each do |user|
          current_user.delay.follow(user)
        end
        render json: { outcome: "followed 50 users" }
      end
    end
  end
end
