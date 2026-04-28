module Articles
  module Destroyer
    module_function

    def call(article)
      # comments will automatically lose the connection to their article once `.destroy` is called,
      # due to the `dependent: nullify` clause, so to remove their notifications,
      # we need to cache the ids in advance
      article_comments_ids = article.comments.ids
      user = article.user

      article.destroy!

      # BustCacheWorker looks up the article by ID after deletion and returns early
      # when it can't find it, so article.user.purge inside EdgeCache::BustArticle is
      # never called.  Explicitly bust the user's profile cache here so that any
      # pinned-article cards pointing to the just-deleted post are evicted.
      EdgeCache::BustUser.call(user)

      Notification.remove_all(notifiable_ids: article.id, notifiable_type: "Article")

      return if article_comments_ids.blank?

      Notification.remove_all(notifiable_ids: article_comments_ids, notifiable_type: "Comment")
    end
  end
end
