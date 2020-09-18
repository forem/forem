class ArticleSuggester
  def initialize(article)
    @article = article
    @total_articles_count = self.class.articles_count
  end

  def articles(max: 4)
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
      other_suggestions(max: max)
    end
  end

  def self.articles_count
    Article.published.estimated_count
  end

  private

  attr_reader :article

  def other_suggestions(max: 4, ids_to_ignore: [])
    ids_to_ignore << article.id
    Article.published
      .where.not(id: ids_to_ignore)
      .where.not(user_id: article.user_id)
      .order(hotness_score: :desc)
      .offset(rand(0..offset))
      .first(max)
  end

  def suggestions_by_tag(max: 4)
    Article.published.tagged_with(cached_tag_list_array, any: true)
      .where.not(user_id: article.user_id)
      .where(tag_suggestion_query)
      .order(hotness_score: :desc)
      .offset(rand(0..offset))
      .first(max)
  end

  def offset
    @total_articles_count > 1000 ? 200 : (@total_articles_count / 10)
  end

  def tag_suggestion_query
    # Fore big communities like DEV we can look at organic page views for indicator.
    # For smaller communities, we'll a basic score check.
    @total_articles_count > 1000 ? "organic_page_views_past_month_count > 5" : "score > 1"
  end

  def cached_tag_list_array
    (article.cached_tag_list || "").split(", ")
  end
end
