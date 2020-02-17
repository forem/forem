require "rails_helper"

RSpec.describe Search::ClassifiedListingEsIndexWorker, type: :worker, elasticsearch: true do
  let(:worker) { subject }

  include_examples "#enqueues_on_correct_queue", "high_priority", [1]

  it "raises an error if record is not found" do
    expect { worker.perform(1234) }.to raise_error(ActiveRecord::RecordNotFound)
  end

  it "indexes classified_listing" do
    classified_listing = FactoryBot.create(:classified_listing)
    expect { classified_listing.elasticsearch_doc }.to raise_error(Elasticsearch::Transport::Transport::Errors::NotFound)
    worker.perform(classified_listing.id)

    elasticsearch_doc = classified_listing.elasticsearch_doc.dig("_source")
    cl_serialized_search_hash = classified_listing.serialized_search_hash.deep_stringify_keys

    # To avoid a mess of parsing timestamps in different timezones, just check the key
    expect(elasticsearch_doc).to have_key("bumped_at")
    expect(cl_serialized_search_hash).to have_key("bumped_at")

    # Test equality except the bumped_at field which is a timestamp - the value is always different
    expect(elasticsearch_doc.except("bumped_at")).to eq(cl_serialized_search_hash.except("bumped_at"))
  end
end
