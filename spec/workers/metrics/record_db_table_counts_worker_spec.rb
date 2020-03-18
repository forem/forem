require "rails_helper"

RSpec.describe Metrics::RecordDbTableCountsWorker, type: :worker do
  default_logger = Rails.logger

  include_examples "#enqueues_on_correct_queue", "low_priority", 1

  describe "#perform" do
    # Override the default Rails logger as these tests require the Timber logger.
    before do
      timber_logger = Timber::Logger.new(nil)
      Rails.logger = ActiveSupport::TaggedLogging.new(timber_logger)
    end

    after { Rails.logger = default_logger }

    it "logs estimated counts in Datadog" do
      allow(DatadogStatsClient).to receive(:gauge)
      described_class.new.perform

      expect(
        DatadogStatsClient,
      ).to have_received(:gauge).with("postgres.db_table_size", 0, Hash).at_least(1)
    end
  end
end
