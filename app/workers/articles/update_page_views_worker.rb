# [PROJECT_ROOT]/app/workers/articles/update_page_views_worker.rb

module Articles
  class UpdatePageViewsWorker
    include Sidekiq::Job

    GOOGLE_REFERRER = "https://www.google.com/".freeze

    sidekiq_options queue: :medium_priority,
                    lock: :until_executing,
                    on_conflict: :replace,
                    retry: false

    def perform(create_params)
      article = Article.find_by(id: create_params["article_id"])
      return unless article&.published?
      return if create_params[:user_id] && article.user_id == create_params[:user_id]

      # --- START: MODIFIED CODE ---
      begin
        PageView.create!(create_params)
      rescue ActiveRecord::RecordNotUnique
        # This is the most likely error. It happens when this job runs twice
        # due to a race condition. It's safe to ignore it, because the page
        # view has already been created. We can simply stop the worker.
        return
      rescue ActiveRecord::RecordInvalid => e
        # This indicates a data problem. We should log it to understand why
        # the params are bad, and then stop the worker.
        Rails.logger.error("Articles::UpdatePageViewsWorker validation failed: #{e.message} for params: #{create_params}")
        return
      end
      # --- END: MODIFIED CODE ---

      updated_count = article.page_views.sum(:counts_for_number_of_views)
      if updated_count > article.page_views_count
        article.update_column(:page_views_count, updated_count)
      end

      return unless create_params["referrer"] == GOOGLE_REFERRER

      Articles::UpdateOrganicPageViewsWorker.perform_at(
        25.minutes.from_now,
        article.id,
      )
    end
  end
end