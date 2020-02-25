require "rails_helper"

RSpec.describe Search::ClassifiedListingEsIndexWorker, type: :worker, elasticsearch: true do
  let(:worker) { subject }

  include_examples "#enqueues_on_correct_queue", "high_priority", [1]

  it "raises an error if record is not found" do
    expect { worker.perform(1234) }.to raise_error(ActiveRecord::RecordNotFound)
  end

  it "indexes classified_listing" do
    classified_listing = FactoryBot.create(:classified_listing)
    expect { classified_listing.elasticsearch_doc }.to raise_error(Search::Errors::Transport::NotFound)
    worker.perform(classified_listing.id)

    elasticsearch_doc = classified_listing.elasticsearch_doc.dig("_source").deep_symbolize_keys
    cl_serialized_search_hash = classified_listing.serialized_search_hash.deep_symbolize_keys

    expect(elasticsearch_doc[:id]).to eq(cl_serialized_search_hash[:id])
    expect(elasticsearch_doc[:author][:name]).to eq(cl_serialized_search_hash[:author][:name])
    expect(elasticsearch_doc[:body_markdown]).to eq(cl_serialized_search_hash[:body_markdown])
  end
end
