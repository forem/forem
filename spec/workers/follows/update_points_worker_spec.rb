require "rails_helper"

RSpec.describe Follows::UpdatePointsWorker, type: :worker do
  include_examples "#enqueues_on_correct_queue", "low_priority", 1

  describe "#perform" do
    let(:worker) { subject }

    let(:user) { create(:user) }
    let(:tag) { create(:tag) }
    let(:article) { create(:article, tags: [tag.name]) }
    let(:second_article) { create(:article, tags: [tag.name]) }
    let(:reaction) { create(:reaction, reactable: article, user: user) }
    let(:page_view) { create(:page_view, user: user, article: article, time_tracked_in_seconds: 100) }

    before do
      user.follow(tag)
    end

    it "calculates scores" do
      follow = Follow.last
      follow.update_column(:explicit_points, 2.2)
      worker.perform(reaction.id, user.id)
      follow.reload
      expect(follow.implicit_points).to be > 0
      expect(follow.reload.points).to eq follow.implicit_points + follow.explicit_points
    end

    it "has higher score with more long page views" do
      follow = Follow.last
      worker.perform(reaction.id, user.id)
      follow.reload
      first_implicit_score = follow.implicit_points

      create(:page_view, user: user, article: second_article, time_tracked_in_seconds: 100)

      worker.perform(reaction.id, user.id)
      follow.reload
      expect(follow.implicit_points).to be > first_implicit_score
    end

    it "has higher score with more reactions" do
      follow = Follow.last
      worker.perform(reaction.id, user.id)
      follow.reload
      first_implicit_score = follow.implicit_points

      create(:reaction, reactable: second_article, user: user)

      worker.perform(reaction.id, user.id)
      follow.reload
      expect(follow.implicit_points).to be > first_implicit_score
    end
  end
end
