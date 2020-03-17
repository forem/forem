class ArticleObserver < ApplicationObserver
  def after_save(article)
    return if Rails.env.development?

    ping_new_article(article)
  rescue StandardError => e
    Rails.logger.error(e)
  end

  def ping_new_article(article)
    return unless article.published && article.published_at > 30.seconds.ago

    url = "#{ApplicationConfig['APP_PROTOCOL']}#{ApplicationConfig['APP_DOMAIN']}"

    message = <<~MESSAGE.chomp
      New Article Published: #{article.title}
      #{url}#{article.path}
    MESSAGE

    SlackBotPingWorker.perform_async(
      message: message,
      channel: "activity",
      username: "article_bot",
      icon_emoji: ":writing_hand:",
    )
  end
end
