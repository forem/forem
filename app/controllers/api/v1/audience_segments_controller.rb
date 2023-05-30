module Api
  module V1
    class AudienceSegmentsController < ApiController
      DEFAULT_PER_PAGE = 30
      MAX_USER_IDS = 10_000
      USER_ATTRIBUTES_FOR_SERIALIZATION = %i[
        id username name twitter_username github_username
        profile_image website_url location summary created_at
      ].freeze

      before_action :authenticate_with_api_key!
      before_action :require_admin
      before_action :restrict_user_ids, only: %i[add_users remove_users]

      def index
        page, per_page = pagination_params
        @segments = scope.including_user_counts.order(id: :desc).page(page).per(per_page)

        render json: @segments
      end

      def show
        @segment = scope.including_user_counts.find(params[:id])

        render json: @segment
      end

      def create
        @segment = AudienceSegment.create!(type_of: "manual")

        render json: @segment, status: :created
      end

      def destroy
        @segment = scope.find(params[:id])

        if DisplayAd.where(audience_segment_id: @segment.id).any?
          render json: { error: "Segments cannot be deleted while in use by any billboards" }, status: :conflict
        else
          @segment.segmented_users.in_batches.delete_all
          result = @segment.destroy
          render json: @segment, status: (result ? :ok : :conflict)
        end
      end

      def users
        @segment = scope.find(params[:id])

        page, per_page = pagination_params
        @users = @segment.users.joins(:profile).select(USER_ATTRIBUTES_FOR_SERIALIZATION).page(page).per(per_page)
      end

      def add_users
        @segment = scope.find(params[:id])

        render json: SegmentedUsers::BulkUpsert.call(@segment, user_ids: @user_ids)
      end

      def remove_users
        @segment = scope.find(params[:id])

        render json: SegmentedUsers::BulkDelete.call(@segment, user_ids: @user_ids)
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

      def pagination_params
        per_page_param = params[:per_page] || DEFAULT_PER_PAGE
        max_per_page = ApplicationConfig["API_PER_PAGE_MAX"] || 1000
        per_page = [per_page_param, max_per_page].map(&:to_i).min

        [params[:page].to_i, per_page]
      end

      def scope
        AudienceSegment.manual
      end
    end
  end
end
