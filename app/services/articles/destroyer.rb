module Articles
  module Destroyer
    module_function

    def call(article)
      author = article.user

      # comments will automatically lose the connection to their article once `.destroy` is called,
      # due to the `dependent: nullify` clause, so to remove their notifications,
      # we need to cache the ids in advance
      article_comments_ids = article.comments.ids

      ActiveRecord::Associations::Preloader.new(
        records: [article],
        associations: [{ reactions: { user: :roles } }, { rating_votes: :user }],
      ).call

      CounterCulture.aggregate_counter_updates do
        article.destroy!
      end

      Notification.remove_all(notifiable_ids: article.id, notifiable_type: "Article")

      if article_comments_ids.present?
        Notification.remove_all(notifiable_ids: article_comments_ids, notifiable_type: "Comment")
      end

      EdgeCache::BustUser.call(author)
    end
  end
end
