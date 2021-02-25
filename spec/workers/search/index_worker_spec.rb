require "rails_helper"

RSpec.describe Search::IndexWorker, type: :worker, elasticsearch: "Tag" do
  let(:worker) { subject }

  include_examples "#enqueues_on_correct_queue", "high_priority", ["Tag", 1]

  it "indexes document" do
    tag = FactoryBot.create(:tag)
    expect { tag.elasticsearch_doc }.to raise_error(Search::Errors::Transport::NotFound)
    worker.perform(tag.class.name, tag.id)

    expect(tag.elasticsearch_doc.dig("_source", "id")).to eql(tag.id)
  end

  it "does not raise an error if record is not found" do
    expect { worker.perform("Tag", 1234) }.not_to raise_error
  end
end
