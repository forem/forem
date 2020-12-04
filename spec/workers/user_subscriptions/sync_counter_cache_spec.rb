require "rails_helper"

RSpec.describe UserSubscriptions::SyncCounterCache, type: :worker do
  include_examples "#enqueues_on_correct_queue", "default"

  describe "#perform" do
    let(:worker) { subject }

    it "syncs counter cache for UserSubscriptions" do
      allow(UserSubscription).to receive(:counter_culture_fix_counts)
      worker.perform
      expect(UserSubscription).to have_received(:counter_culture_fix_counts)
        .with(only: %i[subscriber user_subscription_sourceable])
    end
  end
end
