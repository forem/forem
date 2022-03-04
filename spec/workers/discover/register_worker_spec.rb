require "rails_helper"

RSpec.describe Discover::RegisterWorker, type: :woker do
  include_examples "#enqueues_on_correct_queue", "low_priority"

  describe "#perform" do
    let(:worker) { subject }

    it "registers the Forem with the app_domain" do
      allow(Discover::Register).to receive(:call)
      worker.perform
      expect(Discover::Register).to have_received(:call)
    end
  end
end
