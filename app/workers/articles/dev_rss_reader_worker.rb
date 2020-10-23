# NOTE: [rhymes]
# This script will soon be removed. We need it to collect monitoring data on
# Datadog about the production behavior of the `RssReader` class
module Articles
  class DevRssReaderWorker
    include Sidekiq::Worker

    sidekiq_options queue: :medium_priority, retry: 10

    def perform
      return unless SiteConfig.community_name == "DEV"
      return if Rails.cache.read("cancel_rss_job").present?

      # we force fetch to have realistic data
      RssReader.get_all_articles(force: true)
    end
  end
end
