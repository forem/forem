require "rails_helper"

RSpec.describe Articles::Feed, type: :service do
  let(:user) { create(:user) }
  let!(:feed) { described_class.new(user: user, number_of_articles: 100, page: 1) }
  let!(:article) { create(:article) }
  let!(:hot_story) { create(:article, hotness_score: 1000, score: 1000, published_at: 3.hours.ago) }
  let!(:old_story) { create(:article, published_at: 3.days.ago) }
  let!(:low_scoring_article) { create(:article, score: -1000) }
  let!(:month_old_story) { create(:article, published_at: 1.month.ago) }

  describe "#published_articles_by_tag" do
    let(:unpublished_article) { create(:article, published: false) }
    let(:tag) { "foo" }
    let(:tagged_article) { create(:article, tags: [tag]) }

    it "returns published articles" do
      expect(described_class.new(number_of_articles: 1, page: 1).published_articles_by_tag).to include article
      expect(described_class.new(number_of_articles: 1, page: 1).published_articles_by_tag).not_to include unpublished_article
    end

    context "with tag" do
      it "returns articles with the specified tag" do
        expect(described_class.new(number_of_articles: 1, page: 1, tag: tag).published_articles_by_tag).to include tagged_article
      end
    end
  end

  describe "#top_articles_by_timeframe" do
    let!(:moderately_high_scoring_article) { create(:article, score: 20) }
    let(:result) { feed.top_articles_by_timeframe(timeframe: "week").to_a }

    it "returns articles ordered by score" do
      expect(result.slice(0, 2)).to eq [hot_story, moderately_high_scoring_article]
      expect(result.last).to eq low_scoring_article
    end

    context "with week article timeframe specified" do
      it "only returns articles from this week" do
        expect(feed.top_articles_by_timeframe(timeframe: "week")).not_to include(month_old_story)
      end
    end
  end

  describe "#latest_feed" do
    it "only returns articles with scores above -40" do
      expect(feed.latest_feed).not_to include(low_scoring_article)
    end

    it "returns articles ordered by publishing date descending" do
      expect(feed.latest_feed.last).to eq month_old_story
    end
  end

  describe "#default_home_feed_and_featured_story" do
    # let!(:new_story) { create(:article, published_at: 1.minute.ago) }

    let(:featured_story) { feed.default_home_feed_and_featured_story.first }
    let(:stories) { feed.default_home_feed_and_featured_story.second }

    before { article.update(published_at: 1.week.ago) }

    it "returns a featured article and array of other articles" do
      expect(featured_story).to be_a(Article)
      expect(stories).to be_a(Array)
      expect(stories.first).to be_a(Article)
    end

    it "chooses a featured story with a main image" do
      expect(featured_story).to eq hot_story
    end

    it "doesn't include low scoring stories" do
      expect(stories).not_to include(low_scoring_article)
    end

    context "when user logged in" do
      let(:stories) { feed.default_home_feed_and_featured_story(user_signed_in: true).second }

      it "only includes stories from less than 6 hours ago" do
        expect(stories).not_to include(old_story)
        expect(stories).to include(hot_story)
        expect(stories).not_to include(article)
      end
    end
  end

  describe "#default_home_feed" do
    let!(:new_story) { create(:article, published_at: 10.minutes.ago, score: 10) }

    context "when user is not logged in" do
      let(:stories) { feed.default_home_feed(user_signed_in: false) }

      before { article.update(published_at: 1.week.ago) }

      it "returns array of articles" do
        expect(stories).to be_a(Array)
        expect(stories.first).to be_a(Article)
      end

      it "doesn't include low scoring stories" do
        expect(stories).not_to include(low_scoring_article)
      end
    end

    context "when user logged in" do
      let(:stories) { feed.default_home_feed(user_signed_in: true) }

      it "includes stories from between 2 and 6 hours ago" do
        expect(stories).not_to include(old_story)
        expect(stories).to include(new_story)
      end
    end
  end

  describe "#score_followed_user" do
    context "when article is written by a followed user" do
      before { user.follow(article.user) }

      it "returns a score of 1" do
        expect(feed.score_followed_user(article)).to eq 1
      end
    end

    context "when article is not written by a followed user" do
      it "returns a score of 0" do
        expect(feed.score_followed_user(article)).to eq 0
      end
    end
  end

  describe "#score_followed_organization" do
    let(:organization) { create(:organization) }
    let(:article) { create(:article, organization: organization) }

    context "when article is from a followed organization" do
      before { user.follow(organization) }

      it "returns a score of 1" do
        expect(feed.score_followed_organization(article)).to eq 1
      end
    end

    context "when article is not from a followed organization" do
      it "returns a score of 0" do
        expect(feed.score_followed_organization(article)).to eq 0
      end
    end

    context "when article has no organization" do
      let(:article) { create(:article) }

      it "returns a score of 0" do
        expect(feed.score_followed_organization(article)).to eq 0
      end
    end
  end
end
