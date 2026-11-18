module Api
  module V1
    class OrganizationArticleReactionsController < ApiController
      before_action :authenticate_with_api_key_or_current_user!
      after_action :verify_authorized

      def index
        response.headers["Cache-Control"] = "no-store"
        response.headers["Surrogate-Control"] = "no-store"
        organization = Organization.find(params[:organization_id])
        authorize organization, :article_reactions?

        filters = params.permit(:page, :per_page, :article_id)
        articles = organization.articles.published.from_subforem
        articles = articles.where(id: filters[:article_id]) if filters[:article_id].present?
        reactions = Reaction.public_category.only_articles.where(reactable_id: articles.select(:id))
        if params[:since].present?
          since = parse_since
          unless since
            return error_unprocessable_entity(I18n.t("api.v1.organization_article_reactions_controller.invalid_since"))
          end

          reactions = reactions.where(created_at: since..)
        end

        @reactions = reactions.select(:id, :reactable_id, :category, :created_at, :user_id)
          .preload(:user).order(created_at: :desc, id: :desc)
          .page(filters[:page].to_i.clamp(1, 1000))
          .per(filters.fetch(:per_page, 30).to_i.clamp(1, 100))
        render "api/v1/organization_article_reactions/index", formats: :json
      end

      private

      def parse_since
        Date.iso8601(params[:since].to_s)
        Time.zone.iso8601(params[:since].to_s)
      rescue ArgumentError
        nil
      end
    end
  end
end
