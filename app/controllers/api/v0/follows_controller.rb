module Api
  module V0
    class FollowsController < ApplicationController
      def create
        return unless user_signed_in?

        user_ids = params[:users].map { |h| h["id"] }
        user_ids.each do |user_id|
          Users::FollowJob.perform_later(current_user.id, user_id, "User")
        end
        render json: { outcome: "followed 50 users" }
      end
    end
  end
end
