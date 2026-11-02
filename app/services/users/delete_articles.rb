module Users
  module DeleteArticles
    module_function

    # Matches the widest home page check in EdgeCache::BustArticle/BustComment
    HOME_PAGE_ARTICLES_COUNT = 4
    HOME_PAGE_PURGE_ARGS = [["main_app_home_page"], ["/"]].freeze

    # Articles and their comments are deleted inline, but edge cache purges are
    # enqueued so deleting a prolific author isn't slowed down by HTTP purges
    # for every article, comment and commenter profile.
    #
    # Each article is deleted in the same transaction that enqueues its purges,
    # so if enqueuing fails the article is rolled back and a retry finds it again.
    def call(user)
      # Always read from the database: a loaded association would hand back
      # records a rolled back attempt already marked as deleted.
      articles = Article.where(user_id: user.id)
      return unless articles.exists?

      # The home page checks look articles up by id, so they have to run
      # before the articles are gone.
      home_page_article_ids = Article.published.order(hotness_score: :desc).limit(HOME_PAGE_ARTICLES_COUNT).ids
      home_page_purge_enqueued = false

      articles.find_each do |article|
        bust_home_page = !home_page_purge_enqueued &&
          (home_page_article_ids.include?(article.id) || article.decorate.discussion?)

        Article.transaction do
          delete_article(article)
          if bust_home_page
            EdgeCache::PurgeByKeyWorker.perform_in(BustCacheBaseWorker::AFTER_COMMIT_DELAY, *HOME_PAGE_PURGE_ARGS)
          end
        end
        home_page_purge_enqueued ||= bust_home_page
      end
    end

    def delete_article(article)
      delay = BustCacheBaseWorker::AFTER_COMMIT_DELAY
      article.reactions.delete_all
      commenter_ids = delete_comments(article)
      article.discussion_lock&.delete
      article.context_notes.delete_all
      article.article_activity&.delete
      article.trend_memberships.delete_all
      article.profile_pins.delete_all
      article.delete

      Articles::BustDeletedArticleCacheWorker.perform_in(
        delay, Articles::BustDeletedArticleCacheWorker.attributes_for(article)
      )
      commenter_ids.each { |commenter_id| Users::BustCacheWorker.perform_in(delay, commenter_id) }
    end

    def delete_comments(article)
      commenter_ids = Set.new
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
        EdgeCache::PurgeByKeyWorker.perform_in(BustCacheBaseWorker::AFTER_COMMIT_DELAY, keys, paths)
      end
      commenter_ids
    end
  end
end
