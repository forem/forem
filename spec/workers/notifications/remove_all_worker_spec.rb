require "rails_helper"

RSpec.describe Notifications::RemoveAllWorker, type: :woker do
  include_examples "#enqueues_on_correct_queue", "low_priority", 1

  describe "#perform" do
    let(:worker) { subject }

    before do
      allow(Notifications::RemoveAll).to receive(:call)
    end

    it "calls the service" do
      worker.perform(1, "Article")
      expect(Notifications::RemoveAll).to have_received(:call).with([1], "Article")
    end
  end
end
