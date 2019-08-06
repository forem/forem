class TweetTagRefreshStatsJob < ApplicationJob
  queue_as :tweet_tag_refresh_stats

  def perform(article_id)
    article = Article.find_by(id: article_id)

    TweetTags::RefreshStats.call(article.body_markdown.to_s) if article
  end
end
