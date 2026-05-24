require "rails_helper"

RSpec.describe LiquidEmbedReference, type: :model do
  describe "validations" do
    it "requires tag_name and url" do
      embed = LiquidEmbedReference.new
      expect(embed).not_to be_valid
      expect(embed.errors[:tag_name]).to include("can't be blank")
      expect(embed.errors[:url]).to include("can't be blank")
    end
  end

  describe "scopes" do
    let!(:published_past) { described_class.create!(tag_name: "youtube", url: "a", published: true, published_at: 1.day.ago, score: 10, record: create(:comment)) }
    let!(:published_future) { described_class.create!(tag_name: "youtube", url: "b", published: true, published_at: 1.day.from_now, score: 50, record: create(:comment)) }
    let!(:unpublished_record) { described_class.create!(tag_name: "youtube", url: "c", published: false, published_at: 1.day.ago, score: 2, record: create(:comment)) }

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
        expect(results.map(&:url)).to eq(["b", "a", "c"])
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
end
