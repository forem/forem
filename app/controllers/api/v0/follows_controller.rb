module Api
  module V0
    class FollowsController < ApiController
      before_action :authenticate_with_api_key_or_current_user!, only: [:create]

      def create
        user_ids = params[:users].map { |h| h["id"] }
        user_ids.each do |user_id|
          Users::FollowWorker.perform_async(current_user.id, user_id, "User")
        end
        render json: { outcome: "followed #{user_ids.count} users" }
      end
    end
  end
end
