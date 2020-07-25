require "rails_helper"

RSpec.describe ChatChannels::IndexesMembershipsWorker, type: :worker do
  describe "#perform" do
    let(:chat_channel) { create(:chat_channel) }
    let(:chat_channel_membership) { create(:chat_channel_membership) }

    it "indexes chat channel memberships" do
      allow(ChatChannel).to receive(:find).and_return(chat_channel)
      allow(chat_channel).to receive(:chat_channel_memberships).and_return([chat_channel_membership])
      allow(chat_channel_membership).to receive(:index_to_elasticsearch)

      described_class.new.perform(chat_channel.id)

      expect(chat_channel_membership).to have_received(:index_to_elasticsearch)
    end
  end
end
