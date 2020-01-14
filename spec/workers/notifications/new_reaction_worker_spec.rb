require "rails_helper"

RSpec.describe Notifications::NewReactionWorker, type: :worker do
  let(:reaction_data) { { reactable_type: "Comment", reactable_id: 1, reactable_user_id: 2 } }
  let(:org) { create(:organization) }
  let(:receiver_data) { { klass: "Organization", id: org.id } }
  let(:worker) { subject }

  include_examples "#enqueues_on_correct_queue", "medium_priority", [{}, {}]

  describe "#perform" do
    let(:reaction_service) { Notifications::Reactions::Send }

    before { allow(reaction_service).to receive(:call) }

    it "calls the service" do
      worker.perform(reaction_data, receiver_data)
      allow(reaction_service).to receive(:call).with(reaction_data, org).once
    end

    it "doesn't call if is a receiver is of a wrong class" do
      worker.perform(reaction_data, klass: "Tag", id: 10)
      expect(reaction_service).not_to have_received(:call)
    end

    it "doesn't call if is a receiver doesn't exist" do
      worker.perform(reaction_data, klass: "Organization", id: nil)
      expect(reaction_service).not_to have_received(:call)
    end
  end
end
