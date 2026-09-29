module Users
  module DeleteArticles
    module_function

    # Matches the widest home page check in EdgeCache::BustArticle/BustComment
    HOME_PAGE_ARTICLES_COUNT = 4

    # Articles and their comments are deleted inline, but edge cache purges are
    # enqueued so deleting a prolific author isn't slowed down by HTTP purges
    # for every article, comment and commenter profile.
    def call(user)
      return if user.articles.blank?

      # The home page checks look articles up by id, so they have to run
      # before the articles are gone.
      home_page_article_ids = Article.published.order(hotness_score: :desc).limit(HOME_PAGE_ARTICLES_COUNT).ids
      bust_home_page = false
      commenter_ids = Set.new

      user.articles.find_each do |article|
        bust_home_page ||= home_page_article_ids.include?(article.id) || article.decorate.discussion?

        article.reactions.delete_all
        delete_comments(article, commenter_ids)
        article.discussion_lock&.delete
        article.context_notes.delete_all
        article.article_activity&.delete
        article.trend_memberships.delete_all
        article.profile_pins.delete_all
        article.delete
        Articles::BustDeletedArticleCacheWorker.perform_async(
          Articles::BustDeletedArticleCacheWorker.attributes_for(article),
        )
      end

      commenter_ids.each { |commenter_id| Users::BustCacheWorker.perform_async(commenter_id) }
      EdgeCache::PurgeByKeyWorker.perform_async(["main_app_home_page"], ["/"]) if bust_home_page
    end

    def delete_comments(article, commenter_ids)
      article.comments.includes(:user).find_in_batches do |comments|
        keys = []
        paths = []
        comments.each do |comment|
          comment.reactions.delete_all
          keys << comment.record_key
          paths << comment.path
          commenter_ids << comment.user_id
          comment.delete
        end
        EdgeCache::PurgeByKeyWorker.perform_async(keys, paths)
      end
    end
  end
end
