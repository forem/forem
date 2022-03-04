module Articles
  # This module is responsible for updating a specific page view for a given article and user.
  #
  # @see Articles::UpdatePageViewsWorker for the sibling that's responsible for recording page
  #      views.
  module PageViewUpdater
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
      # Don't record views to unpublished articles.
      return false if Article.unpublished.exists?(id: article_id)
      # Don't record author's own views.
      return false if Article.published.exists?(id: article_id, user_id: user_id)

      page_view = PageView.order(created_at: :desc)
        .find_or_create_by(article_id: article_id, user_id: user_id)

      return true if page_view.new_record?

      page_view.update_column(:time_tracked_in_seconds, page_view.time_tracked_in_seconds + 15)

      true
    end
  end
end
