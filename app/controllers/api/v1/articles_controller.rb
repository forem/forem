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

        embedding = nil
        quoted_vector = nil
        begin
          query_hash = Digest::SHA256.hexdigest(query_text)
          embedding = Rails.cache.fetch("semantic_search_embedding/#{query_hash}", expires_in: 1.hour) do
            Ai::Embedding.new(wrapper: self).call(
              query_text,
              task_type: "RETRIEVAL_QUERY",
              output_dimensionality: 768
            )
          end
          vector_literal = "[#{embedding.to_a.join(',')}]"
          quoted_vector = Article.connection.quote(vector_literal)
        rescue StandardError => e
          Rails.logger.error("Failed to generate embedding for article semantic search: #{e.message}")
        end

        # Try Algolia search if configured and enabled
        algolia_configured = (ApplicationConfig["ALGOLIA_APPLICATION_ID"].present? &&
                              ApplicationConfig["ALGOLIA_API_KEY"].present?) ||
                             (Settings::General.algolia_application_id.present? &&
                              Settings::General.algolia_api_key.present?)
        algolia_enabled = Settings::General.algolia_search_enabled?

        if algolia_configured && algolia_enabled
          algolia_ids = []
          begin
            search_params = {
              hitsPerPage: 100,
              facetFilters: []
            }
            subforem_id = RequestStore.store[:subforem_id]
            if subforem_id.present?
              search_params[:facetFilters] << "subforem_id:#{subforem_id}"
            end

            raw_res = Article.raw_search(query_text, search_params)
            algolia_ids = raw_res["hits"].map { |hit| hit["objectID"].to_i }
          rescue => e
            Rails.logger.warn("Algolia search failed: #{e.message}. Falling back to DB search.")
          end

          if algolia_ids.any?
            # Fetch and validate records from database to ensure they are published
            @articles = Article.published.from_subforem
              .where(id: algolia_ids)
              .where("score >= ?", Settings::UserExperience.index_minimum_score)
              .includes([{ user: :profile }, :organization])

            if quoted_vector.present?
              @articles = @articles.select("articles.*, (semantic_embedding <=> #{quoted_vector}) AS distance")
            end

            indexed_articles = @articles.index_by(&:id)
            ordered_articles = algolia_ids.map { |id| indexed_articles[id] }.compact

            # Apply threshold filter if present
            if params[:threshold].present? && quoted_vector.present?
              threshold_val = params[:threshold].to_f
              ordered_articles = ordered_articles.select do |article|
                distance = article.respond_to?(:distance) && article.distance ? article.distance.to_f : nil
                distance.nil? || distance <= threshold_val
              end
            end

            # Paginate validated results
            paginated_articles = ordered_articles[((page - 1) * per_page)...(page * per_page)] || []

            serialized_articles = paginated_articles.map do |article|
              distance = article.respond_to?(:distance) && article.distance ? article.distance.to_f : nil
              similarity = distance ? (1.0 - distance).round(6) : nil
              article.as_json(only: Api::ArticlesController::INDEX_ATTRIBUTES_FOR_SERIALIZATION).merge(
                "distance" => distance,
                "similarity" => similarity
              )
            end

            render json: serialized_articles
            return
          end
        end

        # Fallback to Database Hybrid Search (requires query embedding)
        if quoted_vector.nil?
          render json: { error: "Failed to generate search embedding" }, status: :service_unavailable
          return
        end

        # 1. Retrieve top 100 keyword search candidate metadata
        cleaned_query = clean_keyword_query(query_text)
        keyword_relation = Article.published.from_subforem
          .where("score >= ?", Settings::UserExperience.index_minimum_score)
          .search_articles(cleaned_query)
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

      private

      STOP_WORDS = Set.new(%w[
        a about above after again against all am an and any are aren't as at be because been before being below
        between both but by can't cannot couldn't did didn't do does doesn't doing don't down during each few
        for from further had hadn't has hasn't have haven't having he he'd he'll he's her here here's hers
        herself him himself his how how's i i'd i'll i'm i've if in into is isn't it it's its itself let's
        me more most mustn't my myself no nor not of off on once only or other ought our ours ourselves out
        over own same shan't she she'd she'll she's should shouldn't so some such than that that's the their
        theirs them themselves then there there's these they they'd they'll they're they've this those through
        to too under until up very was wasn't we we'd we'll we're we've were weren't what what's whatever when
        when's where where's which while who who's whom why why's with won't would wouldn't you you'd you'll
        you're you've your yours yourself yourselves
      ]).freeze

      def clean_keyword_query(query_text)
        return "" if query_text.blank?

        # Remove common English contraction endings (e.g. 's, 't, 'd, 're, 've, 'll, 'm)
        cleaned = query_text.downcase.gsub(/'(s|t|d|re|ve|ll|m)\b/, "")
        # Replace non-alphanumeric characters with spaces
        words = cleaned.gsub(/[^a-z0-9\s]/, " ").split
        # Filter out stop words and single-character words
        cleaned_words = words.reject { |w| w.length <= 1 || STOP_WORDS.include?(w) }

        cleaned_words.empty? ? query_text : cleaned_words.join(" ")
      end
    end
  end
end
