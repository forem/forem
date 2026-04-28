module Articles
  module Destroyer
    module_function

    def call(article)
      # comments will automatically lose the connection to their article once `.destroy` is called,
      # due to the `dependent: nullify` clause, so to remove their notifications,
      # we need to cache the ids in advance
      article_comments_ids = article.comments.ids

        # create a lightweight copy to use for cache purging after destroy
        virtual_article = Article.new(article.attributes)

        article.destroy!

        # purge any edge caches that reference this article (and related records)
        EdgeCache::BustArticle.call(virtual_article)

        Notification.remove_all(notifiable_ids: article.id, notifiable_type: "Article")

        return if article_comments_ids.blank?

        Notification.remove_all(notifiable_ids: article_comments_ids, notifiable_type: "Comment")
    end
  end
end
