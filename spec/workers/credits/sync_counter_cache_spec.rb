require "rails_helper"

RSpec.describe Credits::SyncCounterCache, type: :woker do
  include_examples "#enqueues_on_correct_queue", "low_priority"

  describe "#perform" do
    let(:worker) { subject }

    it "syncs counter cache for credits" do
      allow(Credit).to receive(:counter_culture_fix_counts)
      worker.perform
      expect(Credit).to have_received(:counter_culture_fix_counts).with(only: %i[user organization])
    end
  end
end
