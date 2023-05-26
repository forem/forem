require "rails_helper"

RSpec.describe Reactions::UpdateReactableWorker, throttled_call: true, type: :worker do
  describe "#perform" do
    let(:worker) { subject }

    context "when the reactable is a User" do
      let(:admin) { create(:user, :admin) }
      let(:user) { create(:user) }
      let(:reaction) { create(:reaction, user: admin, category: "vomit", reactable: user) }

      it "recalculates its score" do
        worker.perform(reaction.reactable_id, reaction.reactable_type)
        expect(user.reload.score).to be < -1
      end

      it "doesn't fail if the user doesn't exist" do
        expect do
          worker.perform(User.maximum(:id).to_i + 10, "User")
        end.not_to raise_error
      end
    end

    context "when the reactable is an Article" do
      let(:article) { create(:article) }
      let(:reaction) { create(:reaction, reactable: article) }

      it "recalculates its score" do
        sidekiq_assert_enqueued_with(job: Articles::ScoreCalcWorker, args: [article.id]) do
          worker.perform(reaction.reactable_id, reaction.reactable_type)
        end
      end

      it "syncs its reaction count with a throttled call" do
        expect(article.public_reactions_count).to eq(0)

        worker.perform(reaction.reactable_id, reaction.reactable_type)

        expect(ThrottledCall).to have_received(:perform)
          .with(:sync_reactions_count, throttle_for: instance_of(ActiveSupport::Duration))
        expect(article.reload.public_reactions_count).to eq(1)
      end

      it "doesn't fail if the article doesn't exist" do
        expect do
          worker.perform(Article.maximum(:id).to_i + 10, "Article")
        end.not_to raise_error
        sidekiq_assert_no_enqueued_jobs(only: Articles::ScoreCalcWorker)
        expect(ThrottledCall).not_to have_received(:perform)
      end
    end

    context "when the reactable is a Comment" do
      let(:comment) { create(:comment) }
      let(:reaction) { create(:reaction, reactable: comment) }

      it "updates the comment and recalculates its score" do
        job_args = [comment.id]
        reaction_time = 2.days.from_now

        Timecop.freeze(reaction_time) do
          sidekiq_assert_enqueued_with(job: Comments::CalculateScoreWorker, args: job_args) do
            worker.perform(reaction.reactable_id, reaction.reactable_type)
          end

          expect(comment.reload.updated_at).to be_within(1.second).of(reaction_time)
        end
      end

      it "syncs its reaction count with a throttled call" do
        expect(comment.public_reactions_count).to eq(0)

        worker.perform(reaction.reactable_id, reaction.reactable_type)

        expect(ThrottledCall).to have_received(:perform)
          .with(:sync_reactions_count, throttle_for: instance_of(ActiveSupport::Duration))
        expect(comment.reload.public_reactions_count).to eq(1)
      end

      it "doesn't fail if the comment doesn't exist" do
        expect do
          worker.perform(Comment.maximum(:id).to_i + 10, "Comment")
        end.not_to raise_error
        sidekiq_assert_no_enqueued_jobs(only: Comments::CalculateScoreWorker)
        expect(ThrottledCall).not_to have_received(:perform)
      end
    end
  end
end
