require "rails_helper"

RSpec.describe Search::TagEsIndexWorker, type: :worker, elasticsearch: true do
  let(:worker) { subject }

  include_examples "#enqueues_on_correct_queue", "high_priority", [1]

  it "raises an error if record is not found" do
    expect { worker.perform(1234) }.to raise_error(ActiveRecord::RecordNotFound)
  end

  it "indexes tag" do
    tag = FactoryBot.create(:tag)
    expect { tag.elasticsearch_doc }.to raise_error(Elasticsearch::Transport::Transport::Errors::NotFound)
    worker.perform(tag.id)
    expect(tag.elasticsearch_doc.dig("_source")).to eq(
      tag.serialized_search_hash.stringify_keys,
    )
  end
end
