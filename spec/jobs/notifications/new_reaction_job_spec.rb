require "rails_helper"

RSpec.describe Notifications::NewReactionJob, type: :job do
  let(:reaction_data) { { reactable_type: "Comment", reactable_id: 1, reactable_user_id: 2 } }
  let(:org) { create(:organization) }
  let(:receiver_data) { { klass: "Organization", id: org.id } }

  include_examples "#enqueues_job", "send_new_reaction_notification", [{}, {}, true]

  describe "#perform_now" do
    let(:reaction_service) { double }

    before { allow(reaction_service).to receive(:call) }

    it "calls the service" do
      described_class.perform_now(reaction_data, receiver_data, reaction_service)
      expect(reaction_service).to have_received(:call).with(reaction_data, org).once
    end

    it "doesn't call if is a receiver is of a wrong class" do
      described_class.perform_now(reaction_data, { klass: "Tag", id: 10 }, reaction_service)
      expect(reaction_service).not_to have_received(:call)
    end

    it "doesn't call if is a receiver doesn't exist" do
      described_class.perform_now(reaction_data, { klass: "Organization", id: org.id + 1 }, reaction_service)
      expect(reaction_service).not_to have_received(:call)
    end
  end
end
