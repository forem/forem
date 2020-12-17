require "rails_helper"

RSpec.describe Follows::UpdatePointsWorker, type: :worker do
  include_examples "#enqueues_on_correct_queue", "low_priority", 1

  describe "#perform" do
    let(:worker) { subject }

    let(:user) { create(:user) }
    let(:tag) { create(:tag, name: "tag") }
    let(:second_tag) { create(:tag, name: "secondtag") }
    let(:third_tag) { create(:tag, name: "thirdtag") }
    let(:article) { create(:article, tags: [tag.name]) }
    let(:second_article) { create(:article, tags: [tag.name]) }
    let(:reaction) { create(:reaction, reactable: article, user: user) }
    let(:page_view) { create(:page_view, user: user, article: article, time_tracked_in_seconds: 100) }

    before do
      user.follow(second_tag)
      user.follow(tag)
    end

    it "calculates scores" do
      create(:field_test_membership,
             experiment: :follow_implicit_points, variant: :base, participant_id: user.id)
      follow = Follow.last
      follow.update_column(:explicit_points, 2.2)
      worker.perform(reaction.reactable_id, reaction.user_id)
      follow.reload
      expect(follow.implicit_points).to be > 0
      expect(follow.reload.points.round(2)).to eq (follow.implicit_points + follow.explicit_points).round(2)
    end

    it "has higher score with more long page views" do
      create(:field_test_membership,
             experiment: :follow_implicit_points, variant: :base, participant_id: user.id)
      follow = Follow.last
      worker.perform(reaction.reactable_id, reaction.user_id)
      follow.reload
      first_implicit_score = follow.implicit_points

      create(:page_view, user: user, article: second_article, time_tracked_in_seconds: 100)

      worker.perform(reaction.reactable_id, reaction.user_id)
      follow.reload
      expect(follow.implicit_points).to be > first_implicit_score
    end

    it "has higher score with more reactions" do
      create(:field_test_membership,
             experiment: :follow_implicit_points, variant: :base, participant_id: user.id)
      follow = Follow.last
      worker.perform(reaction.reactable_id, reaction.user_id)
      follow.reload
      first_implicit_score = follow.implicit_points

      create(:reaction, reactable: second_article, user: user)

      worker.perform(reaction.reactable_id, reaction.user_id)
      follow.reload
      expect(follow.implicit_points).to be > first_implicit_score
    end

    it "bumps down tag follow points not included in this calc" do
      follow = Follow.first
      worker.perform(reaction.reactable_id, reaction.user_id)
      expect(follow.reload.points.round(2)).to eq(0.98)
    end

    it "applies inverse bonus to slightly penalize more popular tags" do
      create(:field_test_membership,
             experiment: :follow_implicit_points, variant: :base, participant_id: user.id)
      follow = Follow.last
      tag.update_column(:hotness_score, 1000)
      second_tag.update_column(:hotness_score, 100)
      worker.perform(reaction.reactable_id, reaction.user_id)
      follow.reload
      original_points = follow.points
      tag.update_column(:hotness_score, 50)
      tag.reload
      worker.perform(reaction.reactable_id, reaction.user_id)

      expect(follow.reload.points).to be > original_points # should be higher because tag is now less popular
    end

    context "with field tests in place" do
      # regressions testing a few field test scenarios
      it "returns zero if no_implicit_score field test" do
        create(:field_test_membership,
               experiment: :follow_implicit_points, variant: "no_implicit_score", participant_id: user.id)
        follow = Follow.last
        follow.update_column(:explicit_points, 2.2)
        worker.perform(reaction.reactable_id, reaction.user_id)
        follow.reload
        expect(follow.implicit_points).to eq 0
      end

      it "returns double if double_weight_after_log field test" do
        create(:field_test_membership,
               experiment: :follow_implicit_points, variant: "double_weight_after_log", participant_id: user.id)
        follow = Follow.last
        worker.perform(reaction.reactable_id, reaction.user_id)
        follow.reload
        expect(follow.implicit_points).to be_within(0.9).of(2)
      end

      it "returns double if half_weight_after_log field test" do
        create(:field_test_membership,
               experiment: :follow_implicit_points, variant: "half_weight_after_log", participant_id: user.id)
        follow = Follow.last
        worker.perform(reaction.reactable_id, reaction.user_id)
        follow.reload
        expect(follow.implicit_points).to be_within(0.7).of(0.5)
      end
    end
  end
end
