Rails.application.load_tasks

class SitemapRefreshWorker
  include Sidekiq::Worker

  sidekiq_options queue: :low_priority, retry: 10

  def perform
    sitemap_task = ForemInstance.local? ? "sitemap:refresh:no_ping" : "sitemap:refresh"

    Rake::Task[sitemap_task].invoke
  end
end
