require "rails_helper"

RSpec.describe Articles::Feed, type: :service do
  let!(:feed) { described_class.new(number_of_articles: 100, page: 1) }
  let!(:article) { create(:article) }

  describe "#initialize" do
    it "requires number of articles argument" do
      expect { described_class.new(tag: "foo", page: 1) }.to raise_error(ArgumentError)
    end

    it "does not require the tag argument" do
      expect { described_class.new(number_of_articles: 1, page: 1) }.not_to raise_error
    end
  end

  describe "#published_articles_by_tag" do
    let(:unpublished_article) { create(:article, published: false) }
    let(:tag) { "foo" }
    let(:tagged_article) { create(:article, tags: [tag]) }

    it "returns published articles" do
      expect(described_class.new(number_of_articles: 1, page: 1).published_articles_by_tag).to eq [article]
    end

    context "with tag" do
      it "returns articles with the specified tag" do
        expect(described_class.new(number_of_articles: 1, page: 1, tag: tag).published_articles_by_tag).to eq [tagged_article]
      end
    end
  end

  describe "#top_articles_by_timeframe" do
    let!(:high_scoring_article) { create(:article, score: 100) }

    it "returns articles ordered by score" do
      expect(feed.top_articles_by_timeframe(timeframe: "week")).to eq [high_scoring_article, article]
    end

    context "with week article timeframe specified" do
      let!(:month_old_article) { create(:article, published_at: 1.month.ago) }

      it "only returns articles from this week" do
        expect(feed.top_articles_by_timeframe(timeframe: "week")).not_to include(month_old_article)
      end
    end
  end

  describe "#latest_feed" do
    let!(:low_scoring_article) { create(:article, score: -1000) }
    let!(:new_article) { create(:article) }

    before { article.update(published_at: 1.week.ago) }

    it "only returns articles with scores above -40" do
      expect(feed.latest_feed).not_to include(low_scoring_article)
    end

    it "returns articles ordered by publishing date descending" do
      expect(feed.latest_feed).to eq [new_article, article]
    end
  end

  describe "#default_home_feed" do
    let!(:hot_story) { create(:article, hotness_score: 100, score: 100, published_at: 1.day.ago) }
    let!(:new_story) { create(:article, published_at: 1.minute.ago) }
    let!(:low_scoring_article) { create(:article, score: -1000) }

    let(:featured_story) { feed.default_home_feed.first }
    let(:stories) { feed.default_home_feed.second }

    before { article.update(published_at: 1.week.ago) }

    it "returns a featured article and array of other articles" do
      expect(featured_story).to be_a(Article)
      expect(stories).to be_a(ActiveRecord::Relation)
    end

    it "chooses a featured story with a main image" do
      expect(featured_story).to eq hot_story
    end

    it "doesn't include low scoring stories" do
      expect(stories).not_to include(low_scoring_article)
    end

    context "when user logged in" do
      let(:stories) { feed.default_home_feed(user_signed_in: true).second }

      it "only includes stories from more than 6 hours ago" do
        expect(stories).not_to include(article)
        expect(stories).to include(new_story)
      end
    end
  end
end
