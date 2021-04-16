require "rails_helper"

describe Sidekiq::WorkerRetriesExhaustedReporter, type: :labor do
  let(:job_hash) { { "class" => "TempWorker", "retry" => 15, "retry_count" => 1, "jid" => "123abc" } }

  it "increments worker retries exhausted in Datadog" do
    allow(ForemStatsClient).to receive(:increment)
    described_class.report_final_failure(job_hash)
    expect(ForemStatsClient).to have_received(:increment).with(
      "sidekiq.worker.retries_exhausted",
      tags: [
        "action:dead",
        "worker_name:#{job_hash['class']}",
        "jid:#{job_hash['jid']}",
        "retry:#{job_hash['retry']}",
        "retry_count:#{job_hash['retry_count']}",
      ],
    )
  end
end
