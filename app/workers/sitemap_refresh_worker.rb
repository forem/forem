class SitemapRefreshWorker
  include Sidekiq::Worker

  sidekiq_options queue: :low_priority, retry: 10

  def perform
    Rails.application.load_tasks
    Rake::Task["sitemap:refresh"].invoke
  end
end
