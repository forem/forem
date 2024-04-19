require "rails_helper"

RSpec.describe Comments::CalculateScoreWorker, type: :worker do
  include_examples "#enqueues_on_correct_queue", "medium_priority", 1

  describe "#perform" do
    let(:worker) { subject }

    context "with comment" do
      let(:comment) { create(:comment) }

      before do
        allow(Comments::CalculateScore).to receive(:call)
      end

      it "calls CalculateScore" do
        worker.perform(comment.id)
        expect(Comments::CalculateScore).to have_received(:call).with(comment)
      end
    end

    context "without comment" do
      it "does not break" do
        expect { worker.perform(nil) }.not_to raise_error
      end
    end
  end
end
