module Articles
  class PublishWorker
    include Sidekiq::Worker

    sidekiq_options queue: :medium_priority, lock: :until_executing

    def perform
      # find published articles for which notifications were not set yet (so the context notifications were not created)
      published_articles = Article.where(published: true, published_at: 30.minutes.ago..Time.current)
        .where.missing(:context_notifications_published)
      published_articles.each do |article|
        # send slack notifications
        Slack::Messengers::ArticlePublished.call(article: article)
        # create mentions and notifications
        # Send notifications to any mentioned users, followed by any users who follow the article's author.
        Notification.send_to_mentioned_users_and_followers(article)

        # using nth_published because it doesn't count draft articles by the new author
        from_newish_author = article.nth_published_by_author < 3
        Notification.send_moderation_notification(article) if from_newish_author
      end
    end
  end
end
