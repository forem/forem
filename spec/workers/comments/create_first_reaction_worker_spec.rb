require "rails_helper"

RSpec.describe Comments::CreateFirstReactionWorker, type: :worker do
  include_examples "#enqueues_on_correct_queue", "high_priority", 1

  describe "#perform_now" do
    let(:worker) { subject }

    context "with comment" do
      let_it_be(:article) { create(:article) }
      let_it_be(:comment) { create(:comment, commentable: article) }

      it "creates a first reaction" do
        expect do
          worker.perform(comment.id, comment.user_id)
        end.to change(comment.reactions, :count).by(1)
      end

      it "creates a like reaction" do
        worker.perform(comment.id, comment.user_id)

        expect(comment.reactions.last.category).to eq("like")
      end
    end

    context "without comment" do
      it "does not break" do
        expect { worker.perform(nil, nil) }.not_to raise_error
      end
    end
  end
end
