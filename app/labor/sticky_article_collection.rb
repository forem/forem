class StickyArticleCollection
  attr_accessor :article, :author, :reaction_count_num, :comment_count_num

  def initialize(article, author)
    @article = article
    @author = author
    @reaction_count_num = Rails.env.production? ? 15 : -1
    @comment_count_num = Rails.env.production? ? 7 : -2
  end

  def user_stickies
    author.articles.published
      .limited_column_select
      .tagged_with(article_tags, any: true)
      .where.not(id: article.id).order(published_at: :desc)
      .limit(3)
  end

  def suggested_stickies
    (tag_articles.load + more_articles).sample(3)
  end

  def tag_articles
    @tag_articles ||= Article.published.tagged_with(article_tags, any: true)
      .limited_column_select
      .where("public_reactions_count > ? OR comments_count > ?", reaction_count_num, comment_count_num)
      .where.not(id: article.id).where.not(user_id: article.user_id)
      .where("featured_number > ?", 5.days.ago.to_i)
      .order(Arel.sql("RANDOM()"))
      .limit(3)
  end

  def more_articles
    return [] if tag_articles.size > 6

    Article.published.tagged_with(%w[career productivity discuss explainlikeimfive], any: true)
      .limited_column_select
      .where("comments_count > ?", comment_count_num)
      .where.not(id: article.id).where.not(user_id: article.user_id)
      .where("featured_number > ?", 5.days.ago.to_i)
      .order(Arel.sql("RANDOM()"))
      .limit(10 - tag_articles.size)
  end

  def article_tags
    @article_tags ||= article.cached_tag_list_array - ["discuss"]
  end
end
