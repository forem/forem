require "rails_helper"

RSpec.describe Metrics::RecordDbTableCountsWorker, type: :worker do
  include_examples "#enqueues_on_correct_queue", "low_priority", 1

  describe "#perform" do
    it "logs estimated counts in Datadog" do
      allow(DataDogStatsClient).to receive(:gauge)
      described_class.new.perform

      expect(
        DataDogStatsClient,
      ).to have_received(:gauge).with("postgres.db_table_size", 0, Hash).at_least(1)
    end
  end
end
