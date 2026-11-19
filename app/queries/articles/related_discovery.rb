module Articles
  class RelatedDiscovery
    CANDIDATES_PER_SOURCE = 100
    HNSW_MAX_SCAN_TUPLES = 5_000
    MAX_COSINE_DISTANCE = 0.4
    attr_reader :effective_mode, :matches, :fused_scores

    def initialize(params)
      @params = params
      @query = RelatedQuery.new(params)
      @effective_mode = params.fetch(:mode, "keyword")
      @matches = {}
      @fused_scores = {}
    end

    def call
      unless %w[keyword hybrid].include?(effective_mode)
        raise RelatedQuery::InvalidRequest, I18n.t("api.related_articles.invalid_mode")
      end

      keywords = @query.call # Validate all inputs before any provider request.
      return keywords if effective_mode == "keyword"

      vector = query_vector
      unless vector
        @effective_mode = "keyword"
        return keywords
      end

      # Reciprocal rank fusion assumes each input is ranked by relevance, so the keyword
      # candidates are ranked that way here whatever `sort` the caller asked for.
      keyword_ids = @query.ranked_relation.limit(CANDIDATES_PER_SOURCE).ids
      quoted = Article.connection.quote("[#{vector.join(',')}]")
      distance = "articles.semantic_embedding <=> #{quoted}::vector"
      semantic_ids = semantic_shortlist(distance)
      scores = Hash.new(0.0)
      { "keyword" => keyword_ids, "semantic" => semantic_ids }.each do |source, ids|
        ids.each_with_index do |id, rank|
          scores[id] += 1.0 / (60 + rank + 1)
          (@matches[id] ||= []) << source
        end
      end
      @fused_scores = scores
      ids = scores.keys.sort_by { |id| [-scores[id], -id] }
        .slice((@query.page - 1) * @query.per_page, @query.per_page) || []
      @query.filtered_scope.where(id: ids).in_order_of(:id, ids)
    end

    # One relevance number whatever the mode: the fused score in hybrid, the ts_rank
    # score otherwise.  Comparable within a response, not across responses.
    def relevance_for(article)
      value = effective_mode == "hybrid" ? fused_scores[article.id] : article.try(:discovery_rank)
      value&.to_f&.round(6)
    end

    private

    # Order the bounded shortlist on cosine distance alone so PostgreSQL can answer it
    # from the HNSW index on semantic_embedding, using strict iterative scans so post-index
    # visibility, subforem, score, and date filters do not starve the 100-row shortlist,
    # then enforce the cosine cutoff and tie-break by descending ID over those rows in Ruby.
    def semantic_shortlist(distance)
      rows = with_hnsw_search_config do
        @query.filtered_scope.where.not(semantic_embedding: nil)
          .reorder(Arel.sql("#{distance} ASC"))
          .limit(CANDIDATES_PER_SOURCE)
          .pluck(:id, Arel.sql(distance))
      end

      rows.select { |_id, cosine_distance| cosine_distance <= MAX_COSINE_DISTANCE }
        .sort_by { |id, cosine_distance| [cosine_distance, -id] }
        .map(&:first)
    end

    def with_hnsw_search_config
      conn = Article.connection
      ef_search = CANDIDATES_PER_SOURCE.clamp(40, 1_000)
      conn.execute(
        "SET hnsw.ef_search = #{ef_search}; " \
        "SET hnsw.iterative_scan = strict_order; " \
        "SET hnsw.max_scan_tuples = #{HNSW_MAX_SCAN_TUPLES}",
      )
      yield
    ensure
      if conn&.active? && conn.raw_connection.transaction_status != PG::PQTRANS_INERROR
        conn.execute("RESET hnsw.ef_search; RESET hnsw.iterative_scan; RESET hnsw.max_scan_tuples")
      end
    end

    def query_vector
      digest = Digest::SHA256.hexdigest(@params[:q])
      key = "related_articles/#{Ai::Embedding::DEFAULT_EMBEDDING_MODEL}/#{digest}"
      Rails.cache.fetch(key, expires_in: 1.hour) do
        value = Ai::Embedding.new(wrapper: self, timeout: 3).call(@params[:q], task_type: "RETRIEVAL_QUERY",
                                                                               output_dimensionality: 768)
        unless value.is_a?(Array) && value.length == 768 && value.all? { |n| n.is_a?(Numeric) && n.real? && n.finite? }
          raise "Invalid query embedding"
        end

        value
      end
    rescue StandardError => e
      Rails.logger.warn("Related articles embedding unavailable (#{e.class})")
      nil
    end
  end
end
