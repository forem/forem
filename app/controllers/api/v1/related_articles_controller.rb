module Api
  module V1
    class RelatedArticlesController < ApiController
      before_action :authenticate_with_api_key_or_current_user!
      before_action :disable_caching
      after_action :verify_authorized, unless: -> { response.status == 422 }

      rescue_from Articles::RelatedQuery::InvalidRequest do |error|
        error_unprocessable_entity(error.message)
      end

      def index
        organization = Organization.find(params.require(:organization_id))
        authorize organization, :related_articles?
        @discovery = Articles::RelatedDiscovery.new(params)
        @articles = @discovery.call
          .select(Api::ArticlesController::INDEX_ATTRIBUTES_FOR_SERIALIZATION)
          .includes([{ user: :profile }, :organization]).decorate
        response.headers["X-Discovery-Mode"] = @discovery.effective_mode
        if @discovery.effective_mode == "hybrid"
          response.headers["X-Discovery-Candidate-Limit"] =
            (Articles::RelatedDiscovery::CANDIDATES_PER_SOURCE * 2).to_s
          response.headers["X-Discovery-Exhaustive"] = "false"
        end
        render "api/v1/related_articles/index", formats: :json
      end

      private

      def disable_caching
        response.headers["Cache-Control"] = "no-store"
        response.headers["Surrogate-Control"] = "no-store"
      end
    end
  end
end
