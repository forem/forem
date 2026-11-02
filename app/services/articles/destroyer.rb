module Articles
  module Destroyer
    module_function

    def call(article)
      author = article.user

      # comments will automatically lose the connection to their article once `.destroy` is called,
      # due to the `dependent: nullify` clause, so to remove their notifications,
      # we need to cache the ids in advance
      article_comments_ids = article.comments.ids

      # `dependent: :destroy` on reactions decrements public_reactions_count once per
      # reaction (counter_culture); if the counter has drifted below the real count,
      # that trips the non-negative check constraint and the delete fails, so
      # reconcile it first
      article.sync_reactions_count

      article.destroy!

      Notification.remove_all(notifiable_ids: article.id, notifiable_type: "Article")

      if article_comments_ids.present?
        Notification.remove_all(notifiable_ids: article_comments_ids, notifiable_type: "Comment")
      end

      EdgeCache::BustUser.call(author)
    end
  end
end
