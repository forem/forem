require "rails_helper"

RSpec.describe Search::ChatChannelMembershipEsIndexWorker, type: :worker, elasticsearch: true do
  let(:worker) { subject }

  include_examples "#enqueues_on_correct_queue", "high_priority", [1]

  it "raises an error if record is not found" do
    expect { worker.perform(1234) }.to raise_error(ActiveRecord::RecordNotFound)
  end

  it "indexes chat_channel_membership" do
    chat_channel_membership = FactoryBot.create(:chat_channel_membership)
    expect { chat_channel_membership.elasticsearch_doc }.to raise_error(Elasticsearch::Transport::Transport::Errors::NotFound)
    worker.perform(chat_channel_membership.id)
    expected_hash = chat_channel_membership.serialized_search_hash.stringify_keys
    expect(chat_channel_membership.elasticsearch_doc.dig("_source")).to include(
      expected_hash,
    )
  end
end
