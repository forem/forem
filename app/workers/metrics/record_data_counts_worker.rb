module Metrics
  class RecordDataCountsWorker
    include Sidekiq::Worker
    sidekiq_options queue: :low_priority, retry: 10

    MODELS = [
      Article,
      Comment,
      Listing,
      Notification,
      Organization,
      PageView,
      Podcast,
      PodcastEpisode,
      Profile,
      User,
    ].freeze

    def perform
      MODELS.each do |model|
        db_count = begin
          model.count
        rescue ActiveRecord::QueryCanceled
          model.estimated_count
        end

        Rails.logger.info(message: "db_table_size", table_info: { table_name: model.table_name, table_size: db_count })
        ForemStatsClient.gauge("postgres.db_table_size", db_count, tags: ["table_name:#{model.table_name}"])
      end
    end
  end
end
