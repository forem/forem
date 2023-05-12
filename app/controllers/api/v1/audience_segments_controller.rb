module Api
  module V1
    class AudienceSegmentsController < ApiController
      MAX_USER_IDS = 10_000

      before_action :authenticate!
      before_action :require_admin
      # before_action :restrict_user_ids

      def create
        @segment = AudienceSegment.create!(type_of: "manual")

        render json: @segment
      end

      private

      def require_admin
        authorize AudienceSegment, :access?, policy_class: InternalPolicy
      end

      # def permitted_params
      #   @permitted_params ||= params.permit user_ids: []
      # end

      # def restrict_user_ids
      #   if permitted_params[:user_ids].size > MAX_USER_IDS
      #     render json: { error: "Too many user IDs provided" }, status: :unprocessable_entity
      #   end
      # end
    end
  end
end
