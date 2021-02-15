module Articles
  class UpdatePageViewsWorker
    include Sidekiq::Worker

    sidekiq_options queue: :medium_priority,
                    lock: :until_executing,
                    on_conflict: :replace,
                    retry: 10

    def perform(create_params)
      PageView.create(create_params)

      article = Article.find(create_params["article_id"])
      updated_count = article.page_views.sum(:counts_for_number_of_views)
      if updated_count > article.page_views_count
        article.update_column(:page_views_count, updated_count)
      end

      Articles::UpdateOrganicPageViewsWorker.perform_at(
        1.hour.from_now,
        article.id,
      )
    end
  end
end
