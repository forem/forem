module Articles
  class RelatedQuery
    InvalidRequest = Class.new(StandardError)

    MAX_TERMS = 5
    MAX_QUERY_LENGTH = 500
    MAX_PER_PAGE = 100
    SORTS = %w[recent relevance].freeze
    DEFAULT_SORT = "recent".freeze

    def self.call(...)
      new(...).call
    end

    def initialize(params, subforem_id: RequestStore.store[:subforem_id])
      @params = params
      @subforem_id = subforem_id
    end

    def call
      (sort == "relevance" ? ranked_relation : recent_relation).page(page).per(per_page)
    end

    # Newest first, the ordering this endpoint shipped with.
    def recent_relation
      scored_relation
        .reorder(Arel.sql("(articles.published_at + INTERVAL '0 seconds') DESC, articles.id DESC"))
    end

    # Best match first, tie-broken by recency and then ID so paging stays deterministic.
    def ranked_relation
      scored_relation
        .reorder(Arel.sql("#{rank_expression} DESC, " \
                          "(articles.published_at + INTERVAL '0 seconds') DESC, articles.id DESC"))
    end

    def sort
      value = @params[:sort].presence || DEFAULT_SORT
      raise InvalidRequest, I18n.t("api.related_articles.invalid_sort") unless SORTS.include?(value)

      value
    end

    def page
      bounded_integer(:page, default: 1, maximum: 1000)
    end

    def per_page
      bounded_integer(:per_page, default: 30, maximum: MAX_PER_PAGE)
    end

    def filtered_scope
      scope = Article.published.from_subforem(@subforem_id)
        .where("articles.score >= ?", Settings::UserExperience.index_minimum_score)
      scope = scope.where("articles.published_at >= ?", start_date.beginning_of_day) if start_date
      scope = scope.where("articles.published_at < ?", (end_date + 1.day).beginning_of_day) if end_date
      scope
    end

    private

    def scored_relation
      filtered_scope.where(search_predicate)
        .select(Arel.sql("#{rank_expression} AS discovery_rank"))
    end

    # One tsquery OR-ing every term, so a result's score reflects whichever term matched.
    # ts_rank already accounts for term frequency and the document's field weights, so a
    # title match outranks a passing mention in a long body.
    def rank_expression
      "ts_rank(articles.reading_list_document, #{term_queries.map { |sql| "(#{sql})" }.join(' || ')})"
    end

    def term_queries
      @term_queries ||= search_terms.map do |term|
        tsquery_for(term) || raise(InvalidRequest, I18n.t("api.related_articles.invalid_term"))
      end
    end

    def search_terms
      query = @params[:q]
      raise InvalidRequest, I18n.t("api.related_articles.invalid_query", maximum: MAX_QUERY_LENGTH) unless
        query.is_a?(String) && query.present? && query.length <= MAX_QUERY_LENGTH

      terms = query.split(",").map(&:strip).reject(&:empty?).uniq
      raise InvalidRequest, I18n.t("api.related_articles.invalid_terms", maximum: MAX_TERMS) unless
        terms.size.between?(1, MAX_TERMS)

      terms
    end

    def search_predicate
      term_queries.map { |sql| "(articles.reading_list_document @@ #{sql})" }.join(" OR ")
    end

    # A single-word term keeps the shared builder, including its prefix matching.
    # A multi-word term becomes a phrase query, so the words have to appear next to
    # each other rather than anywhere in the document: "Tiger Data" should not match
    # an article that says "tiger" in one paragraph and "data" in another.
    # Punctuation between words (such as the hyphen in "AWS X-Ray") is preserved so
    # phraseto_tsquery emits the same compound-word positions as to_tsvector.
    #
    # Article.sanitize_search_articles_tsquery stays untouched because
    # Article.search_articles, which backs site-wide search, also uses it.
    def tsquery_for(term)
      normalized = Unaccent.unaccent(term.to_s)
        .downcase
        .gsub(Article::DISALLOWED_TSQUERY_CHARACTERS, " ")
        .squish

      token_ends = []
      normalized.scan(/[[:alnum:]]+/) { token_ends << Regexp.last_match.end(0) }

      return if token_ends.empty?
      return Article.sanitize_search_articles_tsquery(term) if token_ends.one?

      phrase = if token_ends.length > Article::MAX_SEARCH_TSQUERY_TERMS
                 normalized[0...token_ends[Article::MAX_SEARCH_TSQUERY_TERMS - 1]]
               else
                 normalized
               end
      "phraseto_tsquery('simple'::regconfig, #{Article.connection.quote(phrase)})"
    end

    def start_date
      @start_date ||= parse_date(:start)
    end

    def end_date
      @end_date ||= parse_date(:end).tap do |value|
        if value && start_date && value < start_date
          raise InvalidRequest,
                I18n.t("api.related_articles.invalid_interval")
        end
      end
    end

    def parse_date(key)
      value = @params[key]
      return if value.blank?

      unless value.is_a?(String) && value.match?(/\A\d{4}-\d{2}-\d{2}\z/)
        raise InvalidRequest, I18n.t("api.related_articles.invalid_date", parameter: key)
      end

      Date.iso8601(value)
    rescue Date::Error
      raise InvalidRequest, I18n.t("api.related_articles.invalid_date", parameter: key)
    end

    def bounded_integer(key, default:, maximum:)
      value = @params[key]
      return default if value.blank?

      unless value.is_a?(Integer) || (value.is_a?(String) && value.match?(/\A-?\d+\z/))
        raise InvalidRequest, I18n.t("api.related_articles.invalid_pagination", parameter: key)
      end

      value.to_i.clamp(1, maximum)
    end
  end
end
