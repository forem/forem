class ArticleSuggester
  attr_accessor :article

  def initialize(article)
    @article = article
  end

  def articles(max: 4)
    if article.tag_list.any?
      # avoid loading more data if we don't need to
      articles_with_requested_tags = suggestions_by_tag(max: max)
      if articles_with_requested_tags.size == max
        articles_with_requested_tags
      else
        # if there are not enough articles with the requested tags, load other suggestions
        num_remaining_needed = max - articles_with_requested_tags.size
        articles_with_requested_tags.union(other_suggestions(max: num_remaining_needed))
      end
    else
      other_suggestions(max: max)
    end
  end

  private

  def other_suggestions(max: 4)
    Article.published.where(featured: true).
      where.not(id: article.id).
      order("hotness_score DESC").
      includes(:user).
      offset(rand(0..offsets[1])).
      first(max)
  end

  def suggestions_by_tag(max: 4)
    Article.published.tagged_with(article.tag_list, any: true).
      where.not(id: article.id).
      order("hotness_score DESC").
      includes(:user).
      offset(rand(0..offsets[0])).
      first(max)
  end

  def offsets
    Rails.env.production? ? [10, 120] : [0, 0]
  end
end
