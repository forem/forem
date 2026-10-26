module Articles
  class UpdateOrganicPageViewsWorker
    include Sidekiq::Job

    sidekiq_options queue: :medium_priority,
                    lock: :until_executing,
                    on_conflict: :replace,
                    retry: false

    GOOGLE_REFERRER = "https://www.google.com/".freeze

    def perform(article_id)
      # Only the id (for the page_views association) and the column being
      # written are needed; avoid hydrating heavy body/HTML/embedding columns.
      article = Article.select(:id, :organic_page_views_past_month_count).find(article_id)
      google_page_views = article.page_views.where(referrer: GOOGLE_REFERRER)
      update_params = {}
      past_month_count = sum_page_views(google_page_views, 1.month.ago)
      update_params[:organic_page_views_past_month_count] = past_month_count

      article.update_columns(update_params)
    end

    private

    def sum_page_views(relation, timeframe)
      relation.where(created_at: timeframe..).sum(:counts_for_number_of_views)
    end
  end
end
