module Articles
  class RelatedDiscovery
    CANDIDATES_PER_SOURCE = 100
    MAX_COSINE_DISTANCE = 0.4
    attr_reader :effective_mode, :matches

    def initialize(params)
      @params = params
      @query = RelatedQuery.new(params)
      @effective_mode = params.fetch(:mode, "keyword")
      @matches = {}
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

      keyword_ids = keywords.except(:limit, :offset).limit(CANDIDATES_PER_SOURCE).ids
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
      ids = scores.keys.sort_by { |id| [-scores[id], -id] }
        .slice((@query.page - 1) * @query.per_page, @query.per_page) || []
      @query.filtered_scope.where(id: ids).in_order_of(:id, ids)
    end

    private

    # Order the bounded shortlist on cosine distance alone, so PostgreSQL can answer it
    # from the HNSW index on semantic_embedding, then break ties by descending ID over
    # those rows only.  A secondary sort key in SQL would make the index unusable and
    # sort distances across every eligible article instead.
    def semantic_shortlist(distance)
      @query.filtered_scope.where.not(semantic_embedding: nil)
        .where("#{distance} <= ?", MAX_COSINE_DISTANCE)
        .reorder(Arel.sql("#{distance} ASC"))
        .limit(CANDIDATES_PER_SOURCE)
        .pluck(:id, Arel.sql(distance))
        .sort_by { |id, cosine_distance| [cosine_distance, -id] }
        .map(&:first)
    end

    def query_vector
      digest = Digest::SHA256.hexdigest(@params[:q])
      key = "related_articles/#{Ai::Embedding::DEFAULT_EMBEDDING_MODEL}/#{digest}"
      Rails.cache.fetch(key, expires_in: 1.hour) do
        value = Ai::Embedding.new(timeout: 3).call(@params[:q], task_type: "RETRIEVAL_QUERY",
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
