class StickyArticleCollection
  attr_accessor :article, :author, :tag_articles, :more_articles, :reaction_count_num, :comment_count_num
  def initialize(article, author)
    @article = article
    @author = author
    @article_tags = article_tags
    @reaction_count_num = Rails.env.production? ? 15 : -1
    @comment_count_num = Rails.env.production? ? 7 : -2
    @tag_articles = tag_articles
    @more_articles = more_articles
  end

  def user_stickies
    author.articles.
      where(published: true).
      limited_column_select.
      tagged_with(article_tags, any: true).
      where.not(id: article.id).order("published_at DESC").
      limit(2)
  end

  def suggested_stickies
    (tag_articles + more_articles).sample(8)
  end

  def tag_articles
    Article.tagged_with(article_tags, any: true).
      includes(:user).
      where("positive_reactions_count > ? OR comments_count > ?", reaction_count_num, comment_count_num).
      where(published: true).
      where.not(id: article.id, user_id: article.user_id).
      limited_column_select.
      where("featured_number > ?", 5.days.ago.to_i).
      order("RANDOM()").
      limit(8)
  end

  def more_articles
    return [] if tag_articles.size < 6
    Article.tagged_with(["career", "productivity", "discuss", "explainlikeimfive"], any: true).
      includes(:user).
      where("comments_count > ?", comment_count_num).
      limited_column_select.
      where(published: true).
      where.not(id: article.id, user_id: article.user_id).
      where("featured_number > ?", 5.days.ago.to_i).
      order("RANDOM()").
      limit(10 - tag_articles.size)
  end

  def article_tags
    tags = article.cached_tag_list_array
    tags.delete("discuss")
    tags
  end
end
