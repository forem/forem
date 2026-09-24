module Articles
  # This module is responsible for updating a specific page view for a given article and user.
  #
  # @see Articles::UpdatePageViewsWorker for the sibling that's responsible for recording page
  #      views.
  module PageViewUpdater
    EXTENDED_PAGEVIEW_NUMBER = 60
    # @param article_id [Integer]
    # @param user_id [Integer]
    #
    # @return [TrueClass] if we updated or created a PageView
    # @return [FalseClass] if we did not update a PageView
    #
    # @note Regardless of return status, consider the business logic successful unless we raise an
    #       exception.  The return value is present for easing testing.  The `find_or_create_by`
    #       adds a complication in the testing logic
    #       (e.g., `expect { Articles::PageViewUpdater.call }.not_to change(PageView, :count) `
    def self.call(article_id:, user_id:)
      # Don't record views to non-existent or unpublished articles.
      return false unless Article.published.exists?(id: article_id)
      # Don't record author's own views.
      return false if Article.published.from_subforem.exists?(id: article_id, user_id: user_id)

      page_view = PageView.order(created_at: :desc)
        .find_or_create_by(article_id: article_id, user_id: user_id)
      return true if page_view.new_record?

      new_time_mark = page_view.time_tracked_in_seconds + 15
      page_view.update_column(:time_tracked_in_seconds, new_time_mark)
      if new_time_mark == EXTENDED_PAGEVIEW_NUMBER
        FeedEvent.record_journey_for(page_view.user, article: page_view.article, category: :extended_pageview)
        if user_id
          UpdateUserInterestEmbeddingWorker.perform_async(user_id, article_id, 0.05)
          track_article_read(page_view)
        end
      end

      true
    end

    # Emitted to the CDP so Customer.io can trigger campaigns and score
    # conversion goals off real reading behavior. Fires on the transition to
    # EXTENDED_PAGEVIEW_NUMBER rather than on the >= state, so it is
    # at-most-once per page view row. Unlike the FeedEvent above it carries no
    # feed-click attribution requirement -- any 60-second read counts.
    #
    # Keyed to the reader, not the author: Article#trackable_user_ids resolves
    # to the author, so the event is emitted from the User instead.
    def self.track_article_read(page_view)
      article = page_view.article
      user = page_view.user
      return if article.nil? || user.nil?

      user.track!(
        "article_read",
        {
          "article_id" => article.id,
          "title" => article.title,
          # user_signed_in: false so the canonical public URL (including an
          # organization's custom domain) lands in the payload regardless of
          # the request that triggered the read.
          "url" => URL.article(article, user_signed_in: false),
          "tags" => article.decorate.cached_tag_list_array,
          "author_username" => article.user&.username,
          "organization_id" => article.organization_id,
          "subforem_id" => article.subforem_id
        },
      )
    end
    private_class_method :track_article_read
  end
end
