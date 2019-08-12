require "rails_helper"

RSpec.describe Notifications::MentionJob, type: :job do
  include_examples "#enqueues_job", "send_new_mention_notification", 1

  describe "#perform_now" do
    let(:new_mention_service) { double }
    let(:mention) { create(:mention, mentionable: create(:comment, commentable: create(:article))) }

    before do
      allow(new_mention_service).to receive(:call)
    end

    it "calls the service" do
      described_class.perform_now(mention.id, new_mention_service)
      expect(new_mention_service).to have_received(:call)
    end

    it "doesn't call the service when there's no mention" do
      described_class.perform_now(mention.id + 1, new_mention_service)
      expect(new_mention_service).not_to have_received(:call)
    end
  end
end
