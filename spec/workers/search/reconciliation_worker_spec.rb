require "rails_helper"

RSpec.describe Search::ReconciliationWorker, type: :worker, elasticsearch: true do
  include_examples "#enqueues_on_correct_queue", "low_priority", [0]

  describe "#perform" do
    let(:worker) { subject }
    let(:search_tag) { Search::Tag }

    it "Records a matching count" do
      allow(DatadogStatsClient).to receive(:increment)
      create(:tag, :search_indexed)

      search_tag.refresh_index
      worker.perform(search_tag.to_s)

      tags = { search_class: search_tag, db_count: 1, index_count: 1, record_difference: 0, percentage_difference: 0.00, margin_of_error: 0, action: "record_count", record_count: "match" }

      expect(DatadogStatsClient).to have_received(:increment).with(
        "elasticsearch",
        tags: hash_including(tags),
      )
    end

    it "Uses the margin_of_error argument" do
      allow(DatadogStatsClient).to receive(:increment)
      create(:tag, :search_indexed)
      tag2 = create(:tag, :search_indexed)

      search_tag.refresh_index
      tag2.delete

      expect { worker.perform(search_tag.to_s, 1.0) }.not_to raise_error

      tags = { search_class: search_tag, db_count: 1, index_count: 2, record_difference: 1, percentage_difference: 1.0, margin_of_error: 1.0, use_estimated_count: false, action: "record_count", record_count: "match" }

      expect(DatadogStatsClient).to have_received(:increment).with(
        "elasticsearch",
        tags: hash_including(tags),
      )
    end

    it "Uses the use_estimated_count argument" do
      allow(ClassifiedListing).to receive(:estimated_count)

      worker.perform(Search::ClassifiedListing.to_s, 0, true)

      expect(ClassifiedListing).to have_received(:estimated_count).once
    end

    it "Records a mismatching count and raises an error" do
      allow(DatadogStatsClient).to receive(:increment)
      create(:tag, :search_indexed)
      tag2 = create(:tag, :search_indexed)

      search_tag.refresh_index
      tag2.delete

      expect { worker.perform(search_tag.to_s) }.to raise_error(Search::ReconciliationWorker::ReconciliationMismatch)

      tags = { search_class: search_tag, db_count: 1, index_count: 2, record_difference: 1, percentage_difference: 1.0, margin_of_error: 0, use_estimated_count: false, action: "record_count", record_count: "mismatch" }

      expect(DatadogStatsClient).to have_received(:increment).with(
        "elasticsearch",
        tags: hash_including(tags),
      )
    end

    it "Uses the db_count method on the Search class if no model is found" do
      # Piggyback off of Tags index for testing
      stub_const "Search::Base::INDEX_ALIAS", Search::Tag::INDEX_ALIAS
      create(:tag, :search_indexed)
      search_tag.refresh_index

      allow(DatadogStatsClient).to receive(:increment)
      allow(Search::Base).to receive(:db_count).and_return(1)

      tags = { search_class: Search::Base, db_count: 1, index_count: 1, record_difference: 0, percentage_difference: 0.00, margin_of_error: 0, use_estimated_count: false, action: "record_count", record_count: "match" }

      worker.perform(Search::Base.to_s)

      expect(DatadogStatsClient).to have_received(:increment).with(
        "elasticsearch",
        tags: hash_including(tags),
      )
    end

    it "Raises an error if no model or db_count method is found" do
      expect { worker.perform(Search::Base.to_s) }.to raise_error(Search::Errors::SubclassResponsibility)
    end
  end
end
