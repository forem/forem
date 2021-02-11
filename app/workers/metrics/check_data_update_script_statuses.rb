module Metrics
  class CheckDataUpdateScriptStatuses
    include Sidekiq::Worker
    sidekiq_options queue: :low_priority, retry: 10

    def perform
      failed_scripts = DataUpdateScript.failed.where(created_at: 1.day.ago..Time.current)
      failed_scripts.find_each do |script|
        ForemStatsClient.count(
          "data_update_scripts.failures",
          1,
          tags: ["file_name:#{script.file_name}"],
        )
      end
    end
  end
end
