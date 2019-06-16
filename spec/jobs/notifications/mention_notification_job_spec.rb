require "rails_helper"

RSpec.describe Notification::MentionJob, type: :job do
  include_examples "#enqueues_job", "send_mention_notification", [{}, true]

  describe "#perform_now" do
    let(:new_mention_service) { double }

    before do
      allow(:new_mention_service).to receive(:call)
    end

    it "calls the service" do
      mention = create(:mention)
      described_class.perform_now(mention.id, new_mention_service)
      expect(new_mention_service).to have_recieved(:call)
    end
  end
end
