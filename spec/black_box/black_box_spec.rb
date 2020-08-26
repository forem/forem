require "rails_helper"

RSpec.describe BlackBox, type: :black_box do
  describe "#article_hotness_score" do
    let!(:article) { build_stubbed(:article, published_at: Time.current) }

    it "returns higher value for higher score" do
      article = build_stubbed(:article, score: 99, published_at: Time.current)
      lower_article = build_stubbed(:article, score: 70, published_at: Time.current)
      score = described_class.article_hotness_score(article)
      lower_score = described_class.article_hotness_score(lower_article)
      expect(score).to be > lower_score
    end

    it "returns higher value for more recent article" do
      article = build_stubbed(:article, score: 99, published_at: Time.current)
      lower_article = build_stubbed(:article, score: 70, published_at: 5.days.ago)
      score = described_class.article_hotness_score(article)
      lower_score = described_class.article_hotness_score(lower_article)
      expect(score).to be > lower_score
    end
  end

  describe "#comment_quality_score" do
    it "returns the correct score" do
      comment = build_stubbed(:comment, body_markdown: "```#{'hello, world! ' * 20}```")
      reactions = double
      allow(comment).to receive(:reactions).and_return(reactions)
      allow(reactions).to receive(:sum).with(:points).and_return(22)
      expect(described_class.comment_quality_score(comment)).to eq(25)
    end
  end

  describe "#calculate_spaminess" do
    let(:user) { build_stubbed(:user) }
    let(:comment) { build_stubbed(:comment, user: user) }

    it "returns 100 if there is no user" do
      story = instance_double("Comment", user: nil)
      expect(described_class.calculate_spaminess(story)).to eq(100)
    end

    it "returns 25 if there is a recent github_created_at" do
      user = create(:user)
      user.update_column(:github_created_at, 1.day.ago)
      user.update_column(:registered_at, 1.hour.ago)
      article = create(:article, score: 99, published_at: Time.current, user: user)
      expect(described_class.calculate_spaminess(article)).to eq(25)
    end

    it "returns 0 if there is non-recent github_created_at " do
      user = create(:user)
      user.update_column(:github_created_at, 10.days.ago)
      user.update_column(:registered_at, 1.hour.ago)
      article = create(:article, score: 99, published_at: Time.current)
      expect(described_class.calculate_spaminess(article)).to eq(0)
    end

    it "returns 0 if user is trusted even if new social" do
      user = create(:user)
      user.update_column(:github_created_at, 1.day.ago)
      user.update_column(:registered_at, 1.hour.ago)
      user.add_role(:trusted)
      article = create(:article, score: 99, published_at: Time.current)
      expect(described_class.calculate_spaminess(article)).to eq(0)
    end

    it "returns 0 if badge_achievements_count is high" do
      user = create(:user)
      user.update_column(:github_created_at, 1.day.ago)
      user.update_column(:registered_at, 1.hour.ago)
      user.update_column(:badge_achievements_count, 2)
      article = create(:article, score: 99, published_at: Time.current)
      expect(described_class.calculate_spaminess(article)).to eq(0)
    end
  end
end
