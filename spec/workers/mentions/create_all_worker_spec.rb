require "rails_helper"

RSpec.describe Mentions::CreateAllWorker, type: :worker do
  include_examples "#enqueues_on_correct_queue", "default", 1

  describe "#perform" do
    let(:comment) { create(:comment, commentable: create(:article)) }
    let(:worker) { subject }

    before do
      allow(Mentions::CreateAll).to receive(:call).with(comment)
    end

    context "when comment is valid" do
      it "calls on Mentions::CreateAll" do
        worker.perform(comment.id, comment.class.name)

        expect(Mentions::CreateAll).to have_received(:call).with(comment)
      end
    end

    context "when comment is not valid" do
      it "does not error" do
        expect { worker.perform(nil, "Comment") }.not_to raise_error
      end
    end
  end
end
