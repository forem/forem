class ArticleSuggester
  attr_accessor :article
  def initialize(article)
    @article = article
  end

  def articles(num = 4)
    if article.tag_list.any?
      (suggestions_by_tag + other_suggestions(num)).flatten.first(num).to_a
    else
      other_suggestions(num).to_a
    end
  end

  def other_suggestions(num = 4)
    Article.where(featured: true, published: true).
      where.not(id: article.id).
      order("hotness_score DESC").
      includes(:user).
      offset(rand(0..offsets[1])).
      first(num)
  end

  def suggestions_by_tag
    Article.tagged_with(article.tag_list, any: true).
      where(published: true).
      where.not(id: article.id).
      order("hotness_score DESC").
      includes(:user).
      offset(rand(0..offsets[0])).
      first(4)
  end

  def offsets
    Rails.env.production? ? [10, 50] : [0, 0]
  end
end
