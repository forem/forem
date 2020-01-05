# frozen_string_literal: true

require "rails_helper"

RSpec.describe ChatChannels::IndexWorker, type: :worker do
  include_examples "#enqueues_on_correct_queue", "high_priority", 1

  describe "#perform" do
    let(:chat_channel) { double }
    let(:chat_channel_id) { 1 }
    let(:worker) { subject }

    context "when chat_channel is found" do
      before do
        allow(ChatChannel).to receive(:find_by).with(id: chat_channel_id).and_return(chat_channel)
        allow(chat_channel).to receive(:index!)
      end

      it "calls index" do
        worker.perform(chat_channel_id: chat_channel_id)

        expect(chat_channel).to have_received(:index!)
      end
    end

    context "when chat_channel is not found" do
      before do
        allow(ChatChannel).to receive(:find_by).with(id: chat_channel_id).and_return(nil)
      end

      it "doesn't fail" do
        expect { worker.perform(chat_channel_id: chat_channel_id) }.not_to raise_error
      end
    end
  end
end
