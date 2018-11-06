class ArticleObserver < ActiveRecord::Observer
  def after_save(article)
    return if Rails.env.development?
    if article.published && article.published_at > 30.seconds.ago
      SlackBot.delay.ping "New Article Published: #{article.title}\nhttps://dev.to#{article.path}",
                    channel: "activity",
                    username: "article_bot",
                    icon_emoji: ":writing_hand:"

    end
    if article.user.warned == true
      SlackBot.delay.ping "@#{article.user.username} just posted an article.\nThey've been warned since #{article.user.roles.where(name: 'warned')[0].updated_at.strftime('%d %B %Y')}\nhttps://dev.to#{article.path}",
              channel: "warned-user-activity",
              username: "sloan_watch_bot",
              icon_emoji: ":sloan:"
    end
  rescue StandardError
    puts "error"
  end
end
