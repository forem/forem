require "rails_helper"

RSpec.describe Comments::UpdateCommentableLastCommentAtWorker, type: :worker do
  include_examples "#enqueues_on_correct_queue", "high_priority", 1

  describe "#perform_now" do
    let(:worker) { subject }

    it "updates commentable last_comment_at" do
      comment = create(:comment)
      commentable = comment.commentable
      Timecop.freeze do
        old_time = 1.week.ago
        commentable.update(last_comment_at: old_time)
        worker.perform(commentable.id, commentable.class.name)

        expect(commentable.reload.last_comment_at).not_to eq(old_time)
      end
    end
  end
end
