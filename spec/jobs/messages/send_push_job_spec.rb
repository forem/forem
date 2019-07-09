require "rails_helper"

RSpec.describe Messages::SendPushJob, type: :job do
  include_examples "#enqueues_job", "messages_send_push", 456, 789, "<h1>Hello</h1"

  describe "#perform_now" do
    let(:messages_send_push_service) { double }

    context "when no user found" do
      before do
        allow(User).to receive(:find_by)
        allow(messages_send_push_service).to receive(:call)
      end

      it "does not call the service" do
        described_class.perform_now(456, 789, "<html>", messages_send_push_service)
        expect(messages_send_push_service).not_to have_received(:call)
      end
    end

    context "when no chat channel found" do
      before do
        allow(ChatChannel).to receive(:find_by)
        allow(messages_send_push_service).to receive(:call)
      end

      it "does not call the service" do
        described_class.perform_now(456, 789, "<html>", messages_send_push_service)
        expect(messages_send_push_service).not_to have_received(:call)
      end
    end

    context "when user + chat channel" do
      let(:user) { double }
      let(:chat_channel) { double }

      before do
        allow(User).to receive(:find_by).and_return(user)
        allow(ChatChannel).to receive(:find_by).and_return(chat_channel)
        allow(messages_send_push_service).to receive(:call).with(user, chat_channel, "<html>")
      end

      it "does call the service" do
        described_class.perform_now(456, 789, "<html>", messages_send_push_service)
        expect(messages_send_push_service).to have_received(:call).with(user, chat_channel, "<html>")
      end
    end
  end
end
