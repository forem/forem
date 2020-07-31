module Articles
  module Destroyer
    module_function

    def call(article, event_dispatcher = Webhook::DispatchEvent)
      article.destroy!
      Notification.remove_all_without_delay(notifiable_ids: article.id, notifiable_type: "Article")
      if article.comments.exists?
        Notification.remove_all(notifiable_ids: article.comments.ids,
                                notifiable_type: "Comment")
      end
      event_dispatcher.call("article_destroyed", article) if article.published?
    end
  end
end
