class ArticleAnalyticsFetcher
  def update_analytics(user_id)
    articles_to_check = Article.where(user_id: user_id, published: true)
    qualified_articles = get_articles_that_qualify(articles_to_check)
    return if qualified_articles.none?
    fetch_and_update_page_views_and_reaction_counts(qualified_articles, user_id)
  end

  def fetch_and_update_page_views_and_reaction_counts(qualified_articles, user_id)
    qualified_articles.each_slice(15).to_a.each do |chunk|
      pageviews = GoogleAnalytics.new(chunk.pluck(:id), user_id).get_pageviews
      page_views_obj = pageviews.to_h
      chunk.each do |article|
        article.update_columns(previous_positive_reactions_count: article.positive_reactions_count)
        next if article.page_views_count > page_views_obj[article.id].to_i
        article.update_columns(page_views_count: page_views_obj[article.id].to_i)
      end
    end
  end

  def get_articles_that_qualify(articles_to_check)
    qualified_articles = []
    articles_to_check.each do |article|
      if should_fetch(article)
        qualified_articles << article
      end
    end
    qualified_articles
  end

  def should_fetch(article)
    article.positive_reactions_count > article.previous_positive_reactions_count
  end
end