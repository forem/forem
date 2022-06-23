module Api
  module AnalyticsController
    extend ActiveSupport::Concern

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

      @org = Organization.find(analytics_params[:organization_id])
      authorize(@org, :analytics?)
    end

    def load_owner
      @owner = @org || @user
    end

    def validate_date_params
      raise ArgumentError, I18n.t("api.v0.analytics_controller.start_missing") if analytics_params[:start].blank?
      raise ArgumentError, I18n.t("api.v0.analytics_controller.invalid_date_format") unless valid_date_params?
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
