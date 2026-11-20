require "rails_helper"

RSpec.describe LiquidEmbedReference do
  describe "validations" do
    it "requires tag_name and url" do
      embed = described_class.new
      expect(embed).not_to be_valid
      expect(embed.errors[:tag_name]).to include("can't be blank")
      expect(embed.errors[:url]).to include("can't be blank")
    end
  end

  describe "scopes" do
    before do
      described_class.create!(
        tag_name: "youtube", url: "a", published: true, published_at: 1.day.ago, score: 10, record: create(:comment),
      )
      described_class.create!(
        tag_name: "youtube", url: "b", published: true, published_at: 1.day.from_now,
        score: 50, record: create(:comment)
      )
      described_class.create!(
        tag_name: "youtube", url: "c", published: false, published_at: 1.day.ago, score: 2, record: create(:comment),
      )
    end

    describe ".published" do
      it "returns only instances where published is true and the timestamp is actively in the past" do
        results = described_class.published
        expect(results.count).to eq(1)
        expect(results.first.url).to eq("a")
      end
    end

    describe ".unpublished" do
      it "returns instances where published is rigidly false, OR where published_at sits in the future (scheduled)" do
        results = described_class.unpublished
        expect(results.count).to eq(2)
        expect(results.map(&:url)).to contain_exactly("b", "c")
      end
    end

    describe ".popular" do
      it "returns instances hierarchically sorted strictly by score descending" do
        results = described_class.popular
        expect(results.map(&:score)).to eq([50, 10, 2])
        expect(results.map(&:url)).to eq(%w[b a c])
      end
    end

    describe ".by_tag" do
      it "returns only records matching requested tag dynamically" do
        # We manually update one of these just to give diversity to the test scope tags, bypassing sidekiq parsing loops
        described_class.find_by(url: "c").update_columns(tag_name: "twitter")

        results = described_class.by_tag("youtube")
        expect(results.count).to eq(2)
        expect(results.map(&:url)).to contain_exactly("a", "b")

        twitter = described_class.by_tag("twitter")
        expect(twitter.count).to eq(1)
        expect(twitter.first.url).to eq("c")
      end
    end
  end

  describe ".engagement_backoff_interval and .record_engagement_backoff" do
    it "doubles exponentially across age milestones up to MAX_ENGAGEMENT_BACKOFF", :aggregate_failures do
      expect(described_class.engagement_backoff_interval(10.minutes)).to eq(60.seconds)
      expect(described_class.engagement_backoff_interval(45.minutes)).to eq(2.minutes)
      expect(described_class.engagement_backoff_interval(2.hours)).to eq(4.minutes)
      expect(described_class.engagement_backoff_interval(18.hours)).to eq(32.minutes)
      expect(described_class.engagement_backoff_interval(2.days)).to eq(64.minutes)
      expect(described_class.engagement_backoff_interval(10.days)).to eq(256.minutes)
      expect(described_class.engagement_backoff_interval(45.days)).to eq(1024.minutes)
      expect(described_class.engagement_backoff_interval(365.days)).to eq(described_class::MAX_ENGAGEMENT_BACKOFF)
    end

    it "keeps Billboards at 15s and bounds Pages at 5m regardless of age", :aggregate_failures do
      billboard = create(:billboard)
      billboard.update_columns(created_at: 1.year.ago, updated_at: 1.year.ago)
      page = create(:page)
      page.update_columns(created_at: 1.year.ago, updated_at: 1.year.ago)

      expect(described_class.record_engagement_backoff(billboard)).to eq(15.seconds)
      expect(described_class.record_engagement_backoff(page)).to eq(5.minutes)
    end
  end
end
