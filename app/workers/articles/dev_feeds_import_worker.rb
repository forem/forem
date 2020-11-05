# NOTE: [rhymes]
# This script will soon be removed. We need it to collect monitoring data on
# Datadog about the production behavior of the `Feeds::Import` class
module Articles
  class DevFeedsImportWorker
    include Sidekiq::Worker

    sidekiq_options queue: :medium_priority, retry: 10

    def perform(user_ids = [])
      return unless SiteConfig.community_name == "DEV"
      return if Rails.cache.read("cancel_feeds_import").present?

      users = if user_ids.present?
                User.where(id: user_ids)
              else
                User.with_feed
              end

      ::Feeds::Import.call(users: users)
    end
  end
end
