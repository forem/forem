require "rails_helper"

RSpec.describe BlackBox, type: :lib do
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

    it "returns 0 if the article does not have a published_at date" do
      article = build_stubbed(:article, score: 99, published_at: nil)
      score = described_class.article_hotness_score(article)
      expect(score).to eq(0)
    end

    it "adds a 200 point bonus for featured articles" do
      now = Time.current
      article = build_stubbed(:article, score: 99, published_at: now, featured: false)
      featured_article = build_stubbed(:article, score: 99, published_at: now, featured: true)

      base_score = described_class.article_hotness_score(article)
      featured_score = described_class.article_hotness_score(featured_article)

      expect(featured_score - base_score).to eq(200)
    end

    it "adds a 200 point bonus for favorited (gemmed) articles" do
      now = Time.current
      article = build_stubbed(:article, score: 99, published_at: now, favorited_by_user_id: nil)
      favorited_article = build_stubbed(:article, score: 99, published_at: now, favorited_by_user_id: 123)

      base_score = described_class.article_hotness_score(article)
      favorited_score = described_class.article_hotness_score(favorited_article)

      expect(favorited_score - base_score).to eq(200)
    end
  end

  describe "native hotness parity" do
    it "matches the legacy calculation across ages, scores, tags, and curation flags" do
      now = Time.current
      rng = Random.new(424_242)
      tag_lists = [nil, "", "watercooler", "ruby, watercooler", "watercoolers", "discuss, ruby"]

      200.times do
        published_at = now - rng.rand(0..(24 * 12)).hours - rng.rand(0..3599).seconds
        article = build_stubbed(
          :article,
          score: rng.rand(-800..1500),
          comment_score: rng.rand(-50..1500),
          published_at: published_at,
          crossposted_at: rng.rand < 0.2 ? published_at + rng.rand(0..72).hours : nil,
          featured: rng.rand < 0.3,
          favorited_by_user_id: rng.rand < 0.3 ? 1 : nil,
          cached_tag_list: tag_lists.sample(random: rng),
        )

        native = described_class.__send__(:native_article_hotness_score, article, now)
        expect(native).to eq(described_class.__send__(:legacy_article_hotness_score, article, now))
      end
    end

    it "falls back to the legacy calculation outside a UTC zone" do
      article = build_stubbed(:article, score: 10, published_at: 5.days.ago)
      Time.use_zone("America/New_York") do
        expect(described_class.__send__(:native_article_hotness_score, article, Time.current)).to be_nil
        expect(described_class.article_hotness_score(article)).to be_a(Integer)
      end
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
end
