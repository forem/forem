module Articles
  module Destroyer
    module_function

    def call(article)
      article.destroy!
      Notification.remove_all_without_delay(notifiable_id: article.id, notifiable_type: "Article", action: "Published")
      Notification.remove_all(notifiable_id: article.id, notifiable_type: "Article", action: "Reaction")
    end
  end
end
