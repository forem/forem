require "rails_helper"

describe Sidekiq::WorkerRetriesExhaustedReporter, type: :labor do
  it "increments worker retries exhausted in Datadog" do
    allow(DataDogStatsClient).to receive(:increment)
    described_class.report_final_failure("class" => "TempWorker")
    expect(DataDogStatsClient).to have_received(:increment).with(
      "sidekiq.worker.retries_exhausted",
      tags: ["action:dead", "worker_name:TempWorker"],
    )
  end
end
