require "rails_helper"

RSpec.describe Search::ReconciliationWorker, type: :worker, elasticsearch: true do
  include_examples "#enqueues_on_correct_queue", "low_priority", [0]

  describe "#perform" do
    let(:worker) { subject }

    it "Records a matching count" do
      allow(DatadogStatsClient).to receive(:increment)
      create(:tag, :search_indexed)

      Search::Tag.refresh_index
      worker.perform

      tags = { search_class: Search::Tag, db_count: 1, index_count: 1, record_difference: 0, margin_of_error: 0, action: "record_count", record_count: "match" }

      expect(DatadogStatsClient).to have_received(:increment).with(
        "elasticsearch",
        tags: hash_including(tags),
      )
    end

    it "Records a mismatching count and raises an error" do
      allow(DatadogStatsClient).to receive(:increment)
      tag = create(:tag, :search_indexed)

      Search::Tag.refresh_index
      tag.delete

      expect { worker.perform }.to raise_error(Search::ReconciliationWorker::ReconciliationMismatch)

      tags = { search_class: Search::Tag, db_count: 0, index_count: 1, record_difference: 1, margin_of_error: 0, action: "record_count", record_count: "mismatch" }

      expect(DatadogStatsClient).to have_received(:increment).with(
        "elasticsearch",
        tags: hash_including(tags),
      )
    end

    it "Uses the db_count method on the Search class if no model is found" do
      fake_search_class = class_double("Search::Base").as_stubbed_const(transfer_nested_constants: true)

      # Piggyback off of Tags index for testing
      stub_const "Search::Base::INDEX_ALIAS", Search::Tag::INDEX_ALIAS
      create(:tag, :search_indexed)
      Search::Tag.refresh_index

      allow(DatadogStatsClient).to receive(:increment)
      allow(fake_search_class).to receive(:db_count).and_return(1)
      stub_const "#{described_class}::SEARCH_CLASSES", [fake_search_class]

      tags = { search_class: Search::Base, db_count: 1, index_count: 1, record_difference: 0, margin_of_error: 0, action: "record_count", record_count: "match" }

      worker.perform

      expect(DatadogStatsClient).to have_received(:increment).with(
        "elasticsearch",
        tags: hash_including(tags),
      )
    end

    it "Raises an error if no model or db_count method is found" do
      stub_const "#{described_class}::SEARCH_CLASSES", [Search::Base]

      expect { worker.perform }.to raise_error(Search::Errors::SubclassResponsibility)
    end
  end
end
