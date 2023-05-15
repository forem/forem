module Api
  module V1
    class AudienceSegmentsController < ApiController
      DEFAULT_PER_PAGE = 50
      MAX_USER_IDS = 10_000

      before_action :authenticate!
      before_action :require_admin
      before_action :restrict_user_ids, only: %i[add_users remove_users]

      def index
        page = params[:page].to_i
        @segments = AudienceSegment.manual.including_user_counts.order(id: :desc).page(page).per(per_page)

        render json: @segments
      end

      def show
        @segment = AudienceSegment.manual.including_user_counts.find(params[:id])

        render json: @segment
      end

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

      def per_page
        page_param = params[:per_page] || DEFAULT_PER_PAGE
        max_per_page = ApplicationConfig["API_PER_PAGE_MAX"] || 1000
        [page_param, max_per_page].map(&:to_i).min
      end
    end
  end
end
