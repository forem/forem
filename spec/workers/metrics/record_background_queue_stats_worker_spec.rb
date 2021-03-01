require "rails_helper"

RSpec.describe Metrics::RecordBackgroundQueueStatsWorker, type: :worker do
  include_examples "#enqueues_on_correct_queue", "low_priority", 1

  describe "#perform" do
    it "logs estimated counts in Datadog" do
      allow(Loggers::LogWorkerQueueStats).to receive(:call)
      described_class.new.perform

      expect(Loggers::LogWorkerQueueStats).to have_received(:call)
    end
  end
end
