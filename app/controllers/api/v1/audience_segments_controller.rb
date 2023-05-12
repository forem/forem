module Api
  module V1
    class AudienceSegmentsController < ApiController
      MAX_USER_IDS = 10_000

      before_action :authenticate!
      before_action :require_admin
      before_action :restrict_user_ids, only: %i[add_users remove_users]

      def create
        @segment = AudienceSegment.create!(type_of: "manual")

        render json: @segment, status: :created
      end

      def add_users
        @segment = AudienceSegment.manual.find(params[:id])

        render json: BulkSegmentedUsers.upsert(@segment, user_ids: @user_ids)
      end

      def remove_users
        @segment = AudienceSegment.manual.find(params[:id])

        render json: BulkSegmentedUsers.delete(@segment, user_ids: @user_ids)
      end

      private

      def require_admin
        authorize AudienceSegment, :access?, policy_class: InternalPolicy
      end

      def restrict_user_ids
        @user_ids = params.permit(user_ids: []).require(:user_ids)
        return unless @user_ids.size > MAX_USER_IDS

        render json: { error: "Too many user IDs provided" }, status: :unprocessable_entity
      end
    end
  end
end
