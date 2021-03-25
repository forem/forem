# Any time a worker has failed and will no longer retry we want to be
# notified bc manual intervention will be needed to get the
# job to succeed.
module Sidekiq
  class WorkerRetriesExhaustedReporter
    def self.report_final_failure(job)
      tags = [
        "action:dead",
        "worker_name:#{job['class']}",
        "jid:#{job['jid']}",
        "retry:#{job['retry']}",
        "retry_count:#{job['retry_count']}",
      ]
      ForemStatsClient.increment(
        "sidekiq.worker.retries_exhausted", tags: tags
      )
    end
  end
end
