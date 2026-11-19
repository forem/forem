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

      def index
        organization = Organization.find(params[:organization_id])
        authorize organization, :article_analytics?

        page, per_page = pagination_params
        return render json: [] if page > MAX_PAGE

        articles = organization.articles.published.from_subforem
          .select(QUERY_ATTRIBUTES).order(id: :asc)
          .page(page).per(per_page).without_count

        render json: articles.map { |article| serialize_article(article) }
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
    end
  end
end
