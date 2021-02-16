module Articles
  class UpdatePageViewsWorker
    include Sidekiq::Worker

    sidekiq_options queue: :medium_priority,
                    lock: :until_executing,
                    on_conflict: :replace,
                    retry: false

    def perform(create_params)
      PageView.create!(create_params)

      article = Article.find(create_params["article_id"])
      updated_count = article.page_views.sum(:counts_for_number_of_views)
      if updated_count > article.page_views_count
        article.update_column(:page_views_count, updated_count)
      end

      # PageViewsController#create called the method update_organic_page_views
      # at the end. The relationship between the two was 12.5% chance (rand(8))
      # and 1% chance (rand(100)), or roughly 12x more likely for page view
      # updates vs. organic page view updates. We kept a similar relationship
      # between the two workers, this one here is schedule after 2 minutes,
      # organic page view updates after 25 minutes.
      Articles::UpdateOrganicPageViewsWorker.perform_at(
        25.minutes.from_now,
        article.id,
      )
    end
  end
end
