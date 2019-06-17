class ArticleObserver < ApplicationObserver
  def after_save(article)
    return if Rails.env.development?

    ping_new_article(article)
  rescue StandardError => e
    Rails.logger.error(e)
  end

  def ping_new_article(article)
    return unless article.published && article.published_at > 30.seconds.ago

    SlackBotPingJob.perform_later message: "New Article Published: #{article.title}\nhttps://dev.to#{article.path}",
                                  channel: "activity",
                                  username: "article_bot",
                                  icon_emoji: ":writing_hand:"
  end
end
