module Api
  module V0
    class FollowsController < ApiController
      before_action :authenticate_with_api_key_or_current_user!

      def create
        user_ids = params[:users].map { |h| h["id"] }
        user_ids.each do |user_id|
          Users::FollowWorker.perform_async(current_user.id, user_id, "User")
        end
        render json: { outcome: "followed #{user_ids.count} users" }
      end

      def tags
        @follows = @user.follows_by_type("ActsAsTaggableOn::Tag")
          .select(%i[id followable_id followable_type points])
          .includes(:followable)
          .order(points: :desc)
      end
    end
  end
end
