require "rails_helper"

RSpec.describe Search::ReconciliationWorker, type: :worker, elasticsearch: true do
  include_examples "#enqueues_on_correct_queue", "low_priority", [Search::Tag.to_s]

  describe "#perform" do
    let(:worker) { subject }

    it "Records counts to Datadog" do
      search_class = Search::Tag
      create(:tag, :search_indexed)
      search_class.refresh_index

      allow(DatadogStatsClient).to receive(:increment)

      worker.perform(search_class.to_s)

      tags = { search_class: search_class, db_count: 1, index_count: 1, action: "search_reconciliation" }

      expect(DatadogStatsClient).to have_received(:increment).with(
        "elasticsearch",
        tags: hash_including(tags),
      )
    end
  end
end
