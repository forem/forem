module Api
  module V1
    class OrganizationArticleAnalyticsController < ApiController
      before_action :disable_caching
      before_action :authenticate_with_api_key_or_current_user!
      after_action :verify_authorized

      DEFAULT_PER_PAGE = 30
      MAX_PER_PAGE = 100
      MAX_PAGE = 1000
      ATTRIBUTES = %i[id title path user_id organization_id published_at updated_at
                      page_views_count public_reactions_count comments_count].freeze
      QUERY_ATTRIBUTES = (ATTRIBUTES + %i[slug subforem_id]).freeze
      RESPONSE_ATTRIBUTES = ATTRIBUTES.map(&:to_s).freeze
      DAILY_DATE_FORMAT = /\A\d{4}-\d{2}-\d{2}\z/
      MAX_DAILY_RANGE_DAYS = 90

      def index
        organization = Organization.find(params[:organization_id])
        authorize organization, :article_analytics?
        dates, date_error = daily_dates
        return error_unprocessable_entity(date_error) if date_error

        page, per_page = pagination_params
        return render json: [] if page > MAX_PAGE

        articles = organization.articles.published.from_subforem
          .select(QUERY_ATTRIBUTES).order(id: :asc)
          .page(page).per(per_page).without_count

        if dates
          activities = ArticleActivity.where(article_id: articles.map(&:id))
            .daily_counters_between(dates.first, dates.last)
            .index_by(&:article_id)
        end

        render json: articles.map { |article|
          json = serialize_article(article)
          next json unless dates

          json.merge("daily" => daily_metrics(activities[article.id] || ArticleActivity.new, dates))
        }
      end

      private

      def disable_caching
        response.headers["Cache-Control"] = "no-store"
        response.headers["Surrogate-Control"] = "no-store"
      end

      def pagination_params
        pagination = params.permit(:page, :per_page)
        requested_page = pagination[:page].to_i
        page = requested_page.positive? ? requested_page : 1
        requested_per_page = pagination[:per_page].to_i
        per_page = requested_per_page.positive? ? requested_per_page.clamp(1, MAX_PER_PAGE) : DEFAULT_PER_PAGE
        [page, per_page]
      end

      def serialize_article(article)
        article.attributes.slice(*RESPONSE_ATTRIBUTES).merge(
          "page_views_count" => article.page_views_count.to_i,
          "url" => URL.article(article),
        )
      end

      def daily_dates
        return unless params.key?(:start) || params.key?(:end)
        return [nil, daily_error(:start_and_end_required)] unless params.key?(:start) && params.key?(:end)

        start_date = parse_daily_date(params[:start])
        end_date = parse_daily_date(params[:end])
        return [nil, I18n.t("api.v0.analytics_controller.invalid_date_format")] unless start_date && end_date
        return [nil, daily_error(:end_before_start)] if end_date < start_date
        if (end_date - start_date).to_i >= MAX_DAILY_RANGE_DAYS
          return [nil, daily_error(:range_too_long, max: MAX_DAILY_RANGE_DAYS)]
        end

        [start_date..end_date, nil]
      end

      def parse_daily_date(value)
        Date.iso8601(value) if value.is_a?(String) && value.match?(DAILY_DATE_FORMAT)
      rescue Date::Error
        nil
      end

      def daily_error(key, **options)
        I18n.t("api.v1.organization_article_analytics_controller.#{key}", **options)
      end

      def daily_metrics(activity, dates)
        dates.map do |date|
          iso = date.iso8601
          reactions = activity.daily_reactions[iso] || {}
          {
            "date" => iso,
            "page_views" => activity.daily_page_views.dig(iso, "total").to_i,
            "comments" => activity.daily_comments[iso].to_i,
            "reactions" => { "total" => reactions["total"].to_i }
              .merge(ArticleActivity::REACTION_CATEGORIES.index_with { |category| reactions[category].to_i })
          }
        end
      end
    end
  end
end
