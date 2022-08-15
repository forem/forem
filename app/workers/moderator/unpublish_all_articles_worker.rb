module Moderator
  class UnpublishAllArticlesWorker
    include Sidekiq::Job

    sidekiq_options queue: :medium_priority, retry: 10

    def perform(user_id)
      user = User.find_by(id: user_id)
      return unless user

      user.articles.published.find_each do |article|
        if article.has_frontmatter?
          article.body_markdown.sub!(/^published:\s*true\s*$/, "published: false")
        end
        article.published = false
        article.save(validate: false)
        clean_up_notifications(article)
      end
    end

    def clean_up_notifications(article)
      Notification.remove_all_by_action_without_delay(notifiable_ids: article.id,
                                                      notifiable_type: "Article",
                                                      action: "Published")

      ContextNotification.delete_by(context_id: article.id, context_type: "Article", action: "Published")

      return unless article.comments.exists?

      Notification.remove_all(notifiable_ids: article.comments.ids, notifiable_type: "Comment")
    end
  end
end
