module Users
  class ExportBulkDataWorker
    include Sidekiq::Worker

    sidekiq_options queue: :high_priority, retry: 10

    def perform
      Exporter::Admin::Users.export
    rescue StandardError => e
      ForemStatsClient.count("users.export_bulk-data", 1, tags: ["action:failed"])
      Honeybadger.notify(e)
    end
  end
end
