module Articles
  module Destroyer
    module_function

    def call(article, event_dispatcher = Webhook::DispatchEvent)
      # comments will automatically lose the connection to their article once `.destroy` is called,
      # due to the `dependent: nullify` clause, so to remove their notifications,
      # we need to cache the ids in advance
      article_comments_ids = article.comments.ids

      article.destroy!

      Notification.remove_all_without_delay(notifiable_ids: article.id, notifiable_type: "Article")

      if article_comments_ids.present?
        Notification.remove_all(notifiable_ids: article_comments_ids, notifiable_type: "Comment")
      end

      event_dispatcher.call("article_destroyed", article) if article.published?
    end
  end
end
