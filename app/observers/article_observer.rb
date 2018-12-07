class ArticleObserver < ApplicationObserver
  def after_save(article)
    return if Rails.env.development?
    if article.published && article.published_at > 30.seconds.ago
      SlackBot.delay.ping "New Article Published: #{article.title}\nhttps://dev.to#{article.path}",
                    channel: "activity",
                    username: "article_bot",
                    icon_emoji: ":writing_hand:"

    end
    warned_user_ping(article)
  rescue StandardError
    puts "error"
  end
end
