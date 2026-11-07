module Articles
  class CommunityQuery
    MAX_TERMS = 5
    MAX_QUERY_LENGTH = 500
    MAX_PER_PAGE = 100

    def self.call(...)
      new(...).call
    end

    def initialize(params, subforem_id: RequestStore.store[:subforem_id])
      @params = params
      @subforem_id = subforem_id
    end

    def call
      filtered_scope.where(search_predicate)
        .reorder(Arel.sql("(articles.published_at + INTERVAL '0 seconds') DESC, articles.id DESC"))
        .page(page).per(per_page)
    end

    def page
      bounded_integer(:page, default: 1, maximum: 1000)
    end

    def per_page
      bounded_integer(:per_page, default: 30, maximum: MAX_PER_PAGE)
    end

    def filtered_scope
      scope = Article.published.from_subforem(@subforem_id)
        .where("(articles.score + 0) >= ?", Settings::UserExperience.index_minimum_score)
      if start_date
        scope = scope.where("(articles.published_at + INTERVAL '0 seconds') >= ?", start_date.beginning_of_day)
      end
      if end_date
        scope = scope.where("(articles.published_at + INTERVAL '0 seconds') < ?", (end_date + 1.day).beginning_of_day)
      end
      scope
    end

    private

    def search_predicate
      query = @params[:q]
      raise ArgumentError, I18n.t("api.community_articles.invalid_query", maximum: MAX_QUERY_LENGTH) unless
        query.is_a?(String) && query.present? && query.length <= MAX_QUERY_LENGTH

      terms = query.split(",").map(&:strip).reject(&:empty?).uniq
      raise ArgumentError, I18n.t("api.community_articles.invalid_terms", maximum: MAX_TERMS) unless
        terms.size.between?(1, MAX_TERMS)

      predicates = terms.map do |term|
        sql = Article.sanitize_search_articles_tsquery(term)
        raise ArgumentError, I18n.t("api.community_articles.invalid_term") unless sql

        "articles.reading_list_document @@ #{sql}"
      end
      predicates.map { |predicate| "(#{predicate})" }.join(" OR ")
    end

    def start_date
      @start_date ||= parse_date(:start)
    end

    def end_date
      @end_date ||= parse_date(:end).tap do |value|
        if value && start_date && value < start_date
          raise ArgumentError,
                I18n.t("api.community_articles.invalid_interval")
        end
      end
    end

    def parse_date(key)
      value = @params[key]
      return if value.blank?

      unless value.is_a?(String) && value.match?(/\A\d{4}-\d{2}-\d{2}\z/)
        raise ArgumentError, I18n.t("api.community_articles.invalid_date", parameter: key)
      end

      Date.iso8601(value)
    rescue Date::Error
      raise ArgumentError, I18n.t("api.community_articles.invalid_date", parameter: key)
    end

    def bounded_integer(key, default:, maximum:)
      value = @params[key]
      return default if value.blank?

      unless value.is_a?(String) || value.is_a?(Integer)
        raise ArgumentError, I18n.t("api.community_articles.invalid_pagination", parameter: key)
      end

      value.to_i.clamp(1, maximum)
    end
  end
end
