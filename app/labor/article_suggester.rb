class ArticleSuggester
  def initialize(article)
    @article = article
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
        ids_to_ignore: tagged_suggestions.pluck(:id),
      )
      tagged_suggestions.union(other_articles)
    else
      other_suggestions(max: max)
    end
  end

  private

  attr_reader :article

  def other_suggestions(max: 4, ids_to_ignore: [])
    ids_to_ignore << article.id
    Article.published.
      where.not(id: ids_to_ignore).
      where.not(user_id: article.user_id).
      order("hotness_score DESC").
      offset(rand(0..offset)).
      first(max)
  end

  def suggestions_by_tag(max: 4)
    Article.published.tagged_with(cached_tag_list_array, any: true).
      where.not(user_id: article.user_id).
      where("organic_page_views_past_month_count > 5").
      order("hotness_score DESC").
      offset(rand(0..offset)).
      first(max)
  end

  def offset
    Rails.env.production? ? 200 : 0
  end

  def cached_tag_list_array
    (article.cached_tag_list || "").split(", ")
  end
end
