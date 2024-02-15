require "rails_helper"

RSpec.describe Comments::CalculateScoreWorker, type: :worker do
  include_examples "#enqueues_on_correct_queue", "medium_priority", 1

  describe "#perform" do
    let(:worker) { subject }

    context "with comment" do
      let(:article) { create(:article) }
      let(:comment) { create(:comment, commentable: article) }
      let(:root_comment) { instance_double(Comment) }
      let(:user) { instance_double(User, spam?: false) }

      before do
        allow(BlackBox).to receive(:comment_quality_score).and_return(7)
      end

      it "updates the score" do
        worker.perform(comment.id)

        comment.reload
        expect(comment.score).to be(7)
      end

      it "updates the score and updated_at with a penalty if the user is a spammer", :aggregate_failures do
        comment.user.add_role(:spam)
        comment.update_column(:updated_at, 1.day.ago)
        worker.perform(comment.id)
        comment.reload
        expect(comment.score).to be(-493)
        expect(comment.updated_at).to be_within(1.minute).of(Time.current)
      end

      it "calls save on the root comment when given a descendant comment" do
        child_comment = instance_double(Comment)

        allow(root_comment).to receive(:save!)
        allow(child_comment).to receive(:update_columns)
        allow(child_comment).to receive_messages(is_root?: false, root_exists?: true, root: root_comment,
                                                 user: user)
        allow(Comment).to receive(:find_by).with(id: 1).and_return(child_comment)

        worker.perform(1)

        expect(child_comment).to have_received(:is_root?)
        expect(child_comment).to have_received(:root)
        expect(root_comment).to have_received(:save!)
      end

      it "does not call save on the root comment" do
        allow(root_comment).to receive(:save)
        allow(root_comment).to receive(:update_columns)
        allow(root_comment).to receive_messages(is_root?: true, root: root_comment, user: user)
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
