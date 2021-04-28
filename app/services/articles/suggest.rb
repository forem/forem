module Articles
  class Suggest
    MAX_DEFAULT = 4

    def self.call(article, max: MAX_DEFAULT)
      new(article, max: max).call
    end

    def initialize(article, max: MAX_DEFAULT)
      @article = article
      @max = max
      @total_articles_count = Article.published.estimated_count
    end

    def call
      if cached_tag_list_array.any?
        # avoid loading more data if we don't need to
        tagged_suggestions = suggestions_by_tag(max: max)
        return tagged_suggestions if tagged_suggestions.size == max

        # if there are not enough tagged articles, load other suggestions
        # ignoring tagged articles that might be relevant twice, hence avoiding duplicates
        num_remaining_needed = max - tagged_suggestions.size
        other_articles = other_suggestions(
          max: num_remaining_needed,
          ids_to_ignore: tagged_suggestions.map(&:id),
        )
        tagged_suggestions.union(other_articles)
      else
        other_suggestions
      end
    end

    private

    attr_reader :article, :max, :total_articles_count

    def other_suggestions(max: MAX_DEFAULT, ids_to_ignore: [])
      ids_to_ignore << article.id
      Article.published
        .where.not(id: ids_to_ignore)
        .where.not(user_id: article.user_id)
        .order(hotness_score: :desc)
        .offset(rand(0..offset))
        .first(max)
    end

    def suggestions_by_tag(max: MAX_DEFAULT)
      Article
        .published
        .cached_tagged_with_any(cached_tag_list_array)
        .where.not(user_id: article.user_id)
        .where(tag_suggestion_query)
        .order(hotness_score: :desc)
        .offset(rand(0..offset))
        .first(max)
    end

    def offset
      total_articles_count > 1000 ? 200 : (total_articles_count / 10)
    end

    def tag_suggestion_query
      # Fore big communities like DEV we can look at organic page views for indicator.
      # For smaller communities, we'll a basic score check.
      total_articles_count > 1000 ? "organic_page_views_past_month_count > 5" : "score > 1"
    end

    def cached_tag_list_array
      (article.cached_tag_list || "").split(", ")
    end
  end
end
