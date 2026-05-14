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

    def top_contributors
      analytics = AnalyticsService.new(
        @owner,
        start_date: params[:start], end_date: params[:end], article_id: params[:article_id],
      )
      data = analytics.top_contributors
      render json: data.to_json
    end

    def follower_engagement
      analytics = AnalyticsService.new(
        @owner,
        start_date: params[:start], end_date: params[:end],
      )
      data = analytics.follower_engagement
      render json: data.to_json
    end

    # Bundled endpoint: returns every payload the analytics dashboard UI needs
    # in a single response. Consolidating into one request avoids tripping the
    # per-IP Rack::Attack api_throttle (3 GETs/sec), halves middleware overhead,
    # and gives the client a consistent point-in-time snapshot across panels.
    def dashboard
      # When `start` is omitted (Infinity range), fall back to the owner's
      # registration timestamp so we don't fabricate years of empty buckets
      # before the account existed. AnalyticsService also clamps internally,
      # but resolving here keeps the serialized `start_date_floor` consistent
      # with the data the dashboard actually charts.
      effective_start = params[:start].presence || @owner_start_floor.iso8601

      # No HTTP or server-side cache: the dashboard is a personal/owner-scoped
      # view that must reflect new activity (page views, reactions, comments)
      # immediately. Reads now hit the ArticleActivity fast-path (single
      # indexed row lookup), so removing the cache is cheap and keeps the
      # numbers honest. The endpoint is rate-limited at the Rack::Attack
      # layer, so naive reload mashing is already bounded.
      response.headers["Cache-Control"] = "no-store"

      dated = AnalyticsService.new(
        @owner,
        start_date: effective_start, end_date: params[:end], article_id: params[:article_id],
      )
      all_time = AnalyticsService.new(@owner, article_id: analytics_params[:article_id])

      data = {
        historical: dated.grouped_by_day,
        totals: all_time.totals,
        referrers: dated.referrers,
        top_contributors: dated.top_contributors,
        follower_engagement: dated.follower_engagement,
        start_date_floor: @owner_start_floor.iso8601
      }

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
      @owner_start_floor = compute_start_floor.to_date
    end

    # Earliest meaningful date for the current request scope. For per-article
    # views this is the article's publication date — articles can live in an
    # organization created long after they were published (cross-posts), so
    # clamping to the org's creation date would silently hide pre-org
    # activity. For owner-wide views this is the owner's registration / org
    # creation date.
    def compute_start_floor
      if (article_id = analytics_params[:article_id]).present?
        published_at = Article.where(id: article_id).pick(:published_at)
        return published_at if published_at
      end

      (@owner.respond_to?(:registered_at) && @owner.registered_at) || @owner.created_at
    end

    def validate_date_params
      # The bundled `dashboard` endpoint allows an omitted `start` and falls
      # back to the owner's registration date so Infinity range works without
      # the client knowing the account creation date. All other actions still
      # require an explicit `start`. `end` is always validated when supplied
      # so a malformed value can't silently fall back to Time.current and
      # poison the cache key.
      if analytics_params[:start].blank?
        raise ArgumentError, I18n.t("api.v0.analytics_controller.start_missing") unless action_name == "dashboard"

        if analytics_params[:end].present? && !valid_end_param?
          raise ArgumentError, I18n.t("api.v0.analytics_controller.invalid_date_format")
        end

        return
      end

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

    def valid_end_param?
      (analytics_params[:end] =~ /\A\d{4}-\d{1,2}-\d{1,2}\Z/)&.zero?
    end
  end
end
