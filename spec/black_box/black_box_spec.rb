require "rails_helper"

RSpec.describe BlackBox, type: :black_box do
  describe "#article_hotness_score" do
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
  end
end
