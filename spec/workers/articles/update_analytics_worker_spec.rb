require "rails_helper"

RSpec.describe Articles::UpdateAnalyticsWorker, type: :worker do
  include_examples "#enqueues_on_correct_queue", "low_priority", 1

  describe "#perform" do
    let(:worker) { subject }

    before { allow(Articles::AnalyticsUpdater).to receive(:call) }

    context "when user_id a real user" do
      it "calls the service" do
        allow(User).to receive(:find_by).and_return(456)
        worker.perform(456)
        expect(Articles::AnalyticsUpdater).to have_received(:call).with(456)
      end
    end

    context "when user_id not a real user" do
      it "does not call the service" do
        allow(User).to receive(:find_by)
        worker.perform(456)
        expect(Articles::AnalyticsUpdater).not_to have_received(:call)
      end
    end
  end
end
