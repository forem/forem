module Api
  module V1
    class OrganizationArticleReactionsController < ApiController
      before_action :authenticate_with_api_key_or_current_user!
      after_action :verify_authorized

      DEFAULT_PER_PAGE = 30
      MAX_PER_PAGE = 100
      MAX_PAGE = 1000
      SINCE_FORMAT = /\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?(?:Z|[+-](?:0\d|1[0-4]):[0-5]\d)\z/

      def index
        response.headers["Cache-Control"] = "private, no-store"
        response.headers["Surrogate-Control"] = "no-store"
        organization = Organization.find(params[:organization_id])
        authorize organization, :article_reactions?

        filters = params.permit(:page, :per_page, :article_id)
        requested_page = filters[:page].to_i
        page = requested_page.positive? ? requested_page : 1
        requested_per_page = filters[:per_page].to_i
        per_page = requested_per_page.positive? ? requested_per_page.clamp(1, MAX_PER_PAGE) : DEFAULT_PER_PAGE
        articles = organization.articles.published.from_subforem
        if filters.key?(:article_id)
          return render_invalid(:invalid_article_id) unless filters[:article_id].to_s.match?(/\A[1-9]\d*\z/)

          articles = articles.where(id: filters[:article_id])
        end
        reactions = Reaction.public_category.only_articles.where(reactable_id: articles.select(:id))
        if params.key?(:since)
          since = parse_since
          return render_invalid(:invalid_since) unless since

          reactions = reactions.where(created_at: since..)
        end

        return render json: [] if page > MAX_PAGE

        @reactions = reactions.select(:id, :reactable_id, :category, :created_at, :user_id)
          .preload(:user).order(created_at: :desc, id: :desc)
          .page(page).per(per_page)
        render "api/v1/organization_article_reactions/index", formats: :json
      end

      private

      def render_invalid(key)
        error_unprocessable_entity(I18n.t(key, scope: "api.v1.organization_article_reactions_controller"))
      end

      def parse_since
        value = params[:since]
        return unless value.is_a?(String) && value.match?(SINCE_FORMAT)

        Date.iso8601(value)
        Time.zone.iso8601(value)
      rescue ArgumentError
        nil
      end
    end
  end
end
