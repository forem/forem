require "rails_helper"

RSpec.describe Notifications::ModerationNotificationJob do
  include_examples "#enqueues_job", "send_moderation_notification", 458

  describe "#perform_now" do
    let(:id) { rand(1000) }
    let(:moderation_notification_service) { double }
    let(:comment) do
      comment = double
      allow(Comment).to receive(:find_by).and_return(comment)
    end
    let(:mod) do
      last_moderation_time = Time.zone.now - Notifications::Moderation::MODERATORS_AVAILABILITY_DELAY - 2.hours
      create(:user, :trusted, last_moderation_notification: last_moderation_time)
    end

    before do
      allow(moderation_notification_service).to receive(:call)
    end

    describe "When available moderator(s) + comment" do
      it "calls the service" do
        mod
        comment
        check_received_call
      end
    end

    describe "When no available moderator" do
      it "does not call the service" do
        comment
        check_non_received_call
      end
    end

    describe "When no valid comment" do
      it "does not call the service" do
        mod
        check_non_received_call
      end
    end

    describe "When no valid comment + no moderator" do
      it "does not call the service" do
        check_non_received_call
      end
    end

    def check_received_call
      described_class.perform_now(id, moderation_notification_service)
      expect(moderation_notification_service).to have_received(:call)
    end

    def check_non_received_call
      described_class.perform_now(id, moderation_notification_service)
      expect(moderation_notification_service).not_to have_received(:call)
    end
  end
end
