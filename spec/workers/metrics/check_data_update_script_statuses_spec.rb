require "rails_helper"

RSpec.describe Metrics::CheckDataUpdateScriptStatuses, type: :worker do
  include_examples "#enqueues_on_correct_queue", "low_priority", 1

  describe "#perform" do
    it "logs recently failed script" do
      create(:data_update_script)
      create(:data_update_script, status: :failed, created_at: 1.month.ago)
      failed_script = create(:data_update_script, status: :failed)
      allow(ForemStatsClient).to receive(:count)
      described_class.new.perform

      expect(ForemStatsClient).to have_received(:count).once
      expect(
        ForemStatsClient,
      ).to have_received(:count).with(
        "data_update_scripts.failures", 1, { tags: ["file_name:#{failed_script.file_name}"] }
      ).at_least(1)
    end
  end
end
