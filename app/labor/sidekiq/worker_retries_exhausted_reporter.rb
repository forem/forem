module Sidekiq
  class WorkerRetriesExhaustedReporter
    def self.report_final_failure(job)
      tags = ["action:dead", "worker_name:#{job['class']}"]
      DataDogStatsClient.increment(
        "sidekiq.worker.retries_exhausted", tags: tags
      )
    end
  end
end
