module Api
  module V1
    class OrganizationArticleAnalyticsController < ApiController
      before_action :authenticate_with_api_key_or_current_user!
      after_action :verify_authorized

      ATTRIBUTES = %i[id title path user_id organization_id published_at updated_at
                      page_views_count public_reactions_count comments_count].freeze

      def index
        response.headers["Cache-Control"] = "no-store"
        response.headers["Surrogate-Control"] = "no-store"
        organization = Organization.find(params[:organization_id])
        authorize organization, :article_analytics?

        pagination = params.permit(:page, :per_page)
        articles = organization.articles.published.from_subforem
          .select(ATTRIBUTES).order(id: :asc)
          .page(pagination[:page].to_i.clamp(1, 1000))
          .per(pagination.fetch(:per_page, 30).to_i.clamp(1, 100))

        render json: articles.map { |article| article.attributes.merge("url" => URL.url(article.path)) }
      end
    end
  end
end
