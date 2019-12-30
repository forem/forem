require "rails_helper"

RSpec.describe Comments::TouchUserJob, type: :job do
  include_examples "#enqueues_job", "comments_touch_user", 1

  describe "#perform_now" do
    context "with comment" do
      let_it_be(:article) { create(:article) }
      let_it_be(:comment) { create(:comment, commentable: article) }
      let_it_be(:user) { comment.user }
      let_it_be(:touched_at) { 5.minutes.from_now.beginning_of_minute }

      it "touches user updated_at and last_comment_at columns", :aggregate_failures do
        Timecop.freeze(touched_at) do
          described_class.perform_now(comment.id)

          user.reload
          expect(user.updated_at).to eq(touched_at)
          expect(user.last_comment_at).to eq(touched_at)
        end
      end

      it "does not break if the comment has no user" do
        comment.update(user: nil)

        expect { described_class.perform_now(comment.id) }.not_to raise_error
      end
    end

    context "without comment" do
      it "does not break" do
        expect { described_class.perform_now(nil) }.not_to raise_error
      end
    end
  end
end
