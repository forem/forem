module Api
  module V1
    # @note This controller partially authorizes with the ArticlePolicy, in an ideal world, it would
    #       fully authorize.  However, that refactor would require significantly more work.
    class ArticlesController < ApiController
      include Api::ArticlesController

      before_action :authenticate_with_api_key!, only: %i[create update me unpublish semantic_search]
      before_action :validate_article_param_is_hash, only: %i[create update]
      before_action :set_cache_control_headers, only: %i[index show show_by_slug]
      after_action :verify_authorized, only: %i[create]

      def semantic_search
        query_text = params[:q]
        if query_text.blank?
          render json: { error: "q parameter is required" }, status: :bad_request
          return
        end

        per_page = [params.fetch(:per_page, 10).to_i, 50].min
        per_page = [per_page, 1].max

        begin
          embedding = Ai::Embedding.new(wrapper: self).call(
            query_text,
            task_type: "RETRIEVAL_QUERY",
            output_dimensionality: 768
          )
        rescue StandardError => e
          Rails.logger.error("Failed to generate embedding for article semantic search: #{e.message}")
          render json: { error: "Failed to generate search embedding" }, status: :service_unavailable
          return
        end

        vector_literal = "[#{embedding.to_a.join(',')}]"
        quoted_vector = Article.connection.quote(vector_literal)

        @articles = Article.published.from_subforem
          .includes([{ user: :profile }, :organization])
          .select("articles.*, (semantic_embedding <=> #{quoted_vector}) AS distance")
          .where.not(semantic_embedding: nil)
          .where("score >= ?", Settings::UserExperience.index_minimum_score)

        if params[:threshold].present?
          threshold_val = params[:threshold].to_f
          @articles = @articles.where("semantic_embedding <=> #{quoted_vector} <= ?", threshold_val)
        end

        @articles = @articles
          .order(Arel.sql("semantic_embedding <=> #{quoted_vector}"))
          .page(params[:page])
          .per(per_page)

        serialized_articles = @articles.decorate.map do |article|
          distance = article.distance.to_f
          article.as_json(only: Api::ArticlesController::INDEX_ATTRIBUTES_FOR_SERIALIZATION).merge(
            "distance" => distance,
            "similarity" => (1.0 - distance).round(6)
          )
        end

        render json: serialized_articles
      end
    end
  end
end
