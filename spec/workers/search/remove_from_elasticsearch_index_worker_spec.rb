require "rails_helper"

RSpec.describe Search::RemoveFromElasticsearchIndexWorker, type: :worker do
  let(:worker) { subject }

  include_examples "#enqueues_on_correct_queue", "medium_priority", ["SearchClass", 1]

  it "deletes document for given search class" do
    search_class = Search::Tag
    allow(search_class).to receive(:delete_document)
    described_class.new.perform(search_class.to_s, 1)
    expect(search_class).to have_received(:delete_document).with(1)
  end
end
