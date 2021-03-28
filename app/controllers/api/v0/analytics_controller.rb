module Api
  module V0
    class AnalyticsController < ApiController
      respond_to :json

      rescue_from ArgumentError, with: :error_unprocessable_entity
      rescue_from UnauthorizedError, with: :error_unauthorized

      before_action :authenticate_with_api_key_or_current_user!
      before_action :authorize_user_organization
      before_action :load_owner
      before_action :validate_date_params, only: [:historical]

      def totals
        analytics = AnalyticsService.new(@owner, article_id: analytics_params[:article_id])
        data = analytics.totals
        render json: data.to_json
      end

      def historical
        analytics = AnalyticsService.new(
          @owner,
          start_date: params[:start], end_date: params[:end], article_id: params[:article_id],
        )
        data = analytics.grouped_by_day
        render json: data.to_json
      end

      def past_day
        analytics = AnalyticsService.new(
          @owner, start_date: 1.day.ago, article_id: params[:article_id]
        )
        data = analytics.grouped_by_day
        render json: data.to_json
      end

      def referrers
        analytics = AnalyticsService.new(
          @owner,
          start_date: params[:start], end_date: params[:end], article_id: params[:article_id],
        )
        data = analytics.referrers
        render json: data.to_json
      end

      private

      def authorize_user_organization
        return unless analytics_params[:organization_id]

        @org = Organization.find_by(id: analytics_params[:organization_id])
        raise UnauthorizedError unless @org && @user.org_member?(@org)
      end

      def load_owner
        @owner = @org || @user
      end

      def validate_date_params
        raise ArgumentError, "Required 'start' parameter is missing" if analytics_params[:start].blank?

        message = "Date parameters 'start' or 'end' must be in the format of 'yyyy-mm-dd'"
        raise ArgumentError, message unless valid_date_params?
      end

      def analytics_params
        params.permit(:organization_id, :article_id, :start, :end)
      end

      def valid_date_params?
        date_regex = /\A\d{4}-\d{1,2}-\d{1,2}\Z/ # for example, 2019-03-22 or 2019-2-1
        if analytics_params[:end]
          (analytics_params[:start] =~ date_regex)&.zero? && (analytics_params[:end] =~ date_regex)&.zero?
        else
          (analytics_params[:start] =~ date_regex)&.zero?
        end
      end
    end
  end
end
