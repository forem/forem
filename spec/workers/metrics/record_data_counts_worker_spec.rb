require "rails_helper"

RSpec.describe Metrics::RecordDataCountsWorker, type: :worker do
  include_examples "#enqueues_on_correct_queue", "low_priority", 1

  describe "#perform" do
    it "calls count on each model" do
      allow(User).to receive(:count)
      allow(User).to receive(:estimated_count)
      described_class.new.perform
      expect(User).to have_received(:count)
      expect(User).not_to have_received(:estimated_count)
    end

    it "calls estimated_count if count times out" do
      allow(User).to receive(:count).and_raise(ActiveRecord::QueryCanceled)
      allow(User).to receive(:estimated_count)
      described_class.new.perform
      expect(User).to have_received(:count)
      expect(User).to have_received(:estimated_count)
    end

    it "logs estimated counts in Datadog" do
      allow(ForemStatsClient).to receive(:gauge)
      described_class.new.perform

      expect(
        ForemStatsClient,
      ).to have_received(:gauge).with("postgres.db_table_size", 0, tags: Array).at_least(1)
    end
  end
end
