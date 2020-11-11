module Metrics
  class CheckDataUpdateScriptStatuses
    include Sidekiq::Worker
    sidekiq_options queue: :low_priority, retry: 10

    def perform
      DataUpdateScript.failed.find_each do |script|
        DatadogStatsClient.count(
          "data_update_scripts.failures",
          1,
          tags: ["file_name:#{script.file_name}"],
        )
      end
    end
  end
end
