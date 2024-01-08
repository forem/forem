require "rails_helper"

RSpec.describe Comments::CalculateScoreWorker, type: :worker do
  include_examples "#enqueues_on_correct_queue", "medium_priority", 1

  describe "#perform" do
    let(:worker) { subject }

    context "with comment" do
      let(:article) { create(:article) }
      let(:comment) { create(:comment, commentable: article) }

      before do
        allow(BlackBox).to receive(:comment_quality_score).and_return(7)
      end

      it "updates the score" do
        worker.perform(comment.id)

        comment.reload
        expect(comment.score).to be(7)
      end

      it "updates the score with a penalty if the user is a spammer" do
        comment.user.add_role(:spam)
        worker.perform(comment.id)

        comment.reload
        expect(comment.score).to be(-493)
      end

      it "calls save on the root comment when given a descendant comment" do
        child_comment = double
        root_comment = double

        allow(root_comment).to receive(:save!)
        allow(child_comment).to receive(:update_columns)
        allow(child_comment).to receive(:is_root?).and_return(false)
        allow(child_comment).to receive(:root_exists?).and_return(true)
        allow(child_comment).to receive(:root).and_return(root_comment)
        allow(child_comment).to receive(:user).and_return(double(spam?: false))
        allow(Comment).to receive(:find_by).with(id: 1).and_return(child_comment)

        worker.perform(1)

        expect(child_comment).to have_received(:is_root?)
        expect(child_comment).to have_received(:root)
        expect(root_comment).to have_received(:save!)
      end

      it "does not call save on the root comment" do
        root_comment = double

        allow(root_comment).to receive(:save)
        allow(root_comment).to receive(:update_columns)
        allow(root_comment).to receive(:is_root?).and_return(true)
        allow(root_comment).to receive(:root).and_return(root_comment)
        allow(root_comment).to receive(:user).and_return(double(spam?: false))
        allow(Comment).to receive(:find_by).with(id: 1).and_return(root_comment)

        worker.perform(1)

        expect(root_comment).to have_received(:is_root?)
        expect(root_comment).not_to have_received(:root)
        expect(root_comment).not_to have_received(:save)
      end
    end

    context "without comment" do
      it "does not break" do
        expect { worker.perform(nil) }.not_to raise_error
      end
    end
  end
end
