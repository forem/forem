require "rails_helper"

describe Sidekiq::WorkerRetriesExhaustedReporter, type: :labor do
  it "increments worker retries exhausted in Datadog" do
    allow(DatadogStatsClient).to receive(:increment)
    described_class.report_final_failure("class" => "TempWorker")
    expect(DatadogStatsClient).to have_received(:increment).with(
      "sidekiq.worker.retries_exhausted",
      tags: ["action:dead", "worker_name:TempWorker"],
    )
  end
end
