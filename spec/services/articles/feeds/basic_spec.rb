require "rails_helper"

RSpec.describe Articles::Feeds::Basic, type: :service do
  let(:user) { create(:user) }
  let(:second_user) { create(:user) }
  let(:unique_tag_name) { "foo" }
  let!(:article) { create(:article, hotness_score: 10) }
  let!(:hot_story) { create(:article, hotness_score: 1000, score: 1000, published_at: 3.hours.ago, user_id: second_user.id) }
  let!(:old_story) { create(:article, hotness_score: 500, published_at: 3.days.ago, tags: unique_tag_name) }
  let!(:low_scoring_article) { create(:article, score: -1000) }
  let!(:month_old_story) { create(:article, published_at: 1.month.ago) } # rubocop:disable RSpec/LetSetup

  context "without a user" do
    let(:feed) { described_class.new(user: nil, number_of_articles: 100, page: 1) }

    it "returns articles with score above 0 in order of hotness score" do
      result = feed.feed
      expect(result.first).to eq hot_story
      expect(result.second).to eq old_story
      expect(result.third).to eq article
      expect(result).not_to include(low_scoring_article)
    end
  end

  context "with a user" do
    let(:feed) { described_class.new(user: user, number_of_articles: 100, page: 1) }

    it "returns articles with score above 0 sorted by user preference scores" do
      allow(feed).to receive(:user_following_users_ids).and_return([old_story.user_id])
      old_story_tag = Tag.find_by(name: unique_tag_name)
      old_story_tag.update(points: 10)
      allow(feed).to receive(:user_followed_tags).and_return([old_story_tag])

      result = feed.feed
      expect(result.first).to eq old_story
      expect(result.second).to eq hot_story
      expect(result.third).to eq article
      expect(result).not_to include(low_scoring_article)
    end

    it "does not load blocked articles" do
      create(:user_block, blocker: user, blocked: second_user, config: "default")
      result = feed.feed
      expect(result).not_to include(hot_story)
    end
  end
end
