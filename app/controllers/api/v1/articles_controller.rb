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
        page = [params[:page].to_i, 1].max

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

        # 1. Retrieve top 100 keyword search candidate metadata
        keyword_relation = Article.published.from_subforem
          .where("score >= ?", Settings::UserExperience.index_minimum_score)
          .search_articles(query_text)
          .limit(100)
        keyword_data = keyword_relation.pluck(:id, :score, :published_at)

        # 2. Retrieve top 100 semantic search candidate metadata
        semantic_relation = Article.published.from_subforem
          .where.not(semantic_embedding: nil)
          .where("score >= ?", Settings::UserExperience.index_minimum_score)
          .order(Arel.sql("semantic_embedding <=> #{quoted_vector}"))
          .limit(100)
        semantic_data = semantic_relation.pluck(:id, :score, :published_at)

        # 3. Combine rankings using Reciprocal Rank Fusion (RRF) and apply boosts
        keyword_ids = []
        article_metadata = {}
        keyword_data.each_with_index do |(id, score, published_at), index|
          keyword_ids << id
          article_metadata[id] = { score: score, published_at: published_at }
        end

        semantic_ids = []
        semantic_data.each_with_index do |(id, score, published_at), index|
          semantic_ids << id
          article_metadata[id] ||= { score: score, published_at: published_at }
        end

        k = 60
        scores = Hash.new(0.0)

        keyword_ids.each_with_index do |id, index|
          scores[id] += 1.0 / (k + index + 1)
        end

        semantic_ids.each_with_index do |id, index|
          scores[id] += 1.0 / (k + index + 1)
        end

        # Apply quality & recency boost
        now = Time.current
        boosted_scores = {}
        scores.each do |id, rrf_score|
          meta = article_metadata[id]
          next unless meta

          # Recency Boost (reciprocal decay over time)
          published_at = meta[:published_at] || now
          days_ago = [ (now - published_at) / 1.day, 0.0 ].max
          recency_score = 1.0 / (days_ago + 1.0)
          recency_multiplier = 1.0 + 1.0 * recency_score

          # Quality Boost (logarithmic scale)
          score_val = [ meta[:score].to_f, 0.0 ].max
          quality_score = Math.log(score_val + 1.0)
          quality_multiplier = 1.0 + 0.1 * quality_score

          boosted_scores[id] = rrf_score * recency_multiplier * quality_multiplier
        end

        sorted_ids = boosted_scores.keys.sort_by { |id| -boosted_scores[id] }

        # 4. Paginate IDs
        paginated_ids = sorted_ids[((page - 1) * per_page)...(page * per_page)] || []

        # 5. Fetch fully-hydrated records for the current page
        @articles = Article.published.from_subforem
          .includes([{ user: :profile }, :organization])
          .select("articles.*, (semantic_embedding <=> #{quoted_vector}) AS distance")
          .where(id: paginated_ids)

        # 6. Apply threshold filter if present
        if params[:threshold].present?
          threshold_val = params[:threshold].to_f
          @articles = @articles.where("semantic_embedding <=> #{quoted_vector} <= ?", threshold_val)
        end

        # Map back to preserve RRF order (also filters out any records filtered by threshold)
        indexed_articles = @articles.index_by(&:id)
        ordered_articles = paginated_ids.map { |id| indexed_articles[id] }.compact

        serialized_articles = ordered_articles.map do |article|
          distance = article.respond_to?(:distance) && article.distance ? article.distance.to_f : nil
          similarity = distance ? (1.0 - distance).round(6) : nil
          article.as_json(only: Api::ArticlesController::INDEX_ATTRIBUTES_FOR_SERIALIZATION).merge(
            "distance" => distance,
            "similarity" => similarity
          )
        end

        render json: serialized_articles
      end
    end
  end
end
