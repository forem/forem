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
    let(:tagged_article) { create(:article, tags: tag) }

    it "returns published articles" do
      expect(feed.published_articles_by_tag).to include article
      expect(feed.published_articles_by_tag).not_to include unpublished_article
    end

    context "with tag" do
      it "returns articles with the specified tag" do
        expect(described_class.new(tag: tag).published_articles_by_tag).to include tagged_article
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
      let(:result) { feed.default_home_feed_and_featured_story(user_signed_in: true) }
      let(:featured_story) { result.first }
      let(:stories) { result.second }

      it "only includes stories from less than 6 hours ago" do
        expect(stories).not_to include(old_story)
        expect(stories).not_to include(article)

        # Ideally we'd test for hot_story in the stories list, but the random offset selection makes that random
        expect(featured_story).to eq(hot_story)
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

  describe "#score_randomness" do
    context "when random number is less than 0.6 but greater than 0.3" do
      it "returns 6" do
        allow(feed).to receive(:rand).and_return(0.5)
        expect(feed.score_randomness).to eq 6
      end
    end

    context "when random number is less than 0.3" do
      it "returns 3" do
        allow(feed).to receive(:rand).and_return(0.1)
        expect(feed.score_randomness).to eq 3
      end
    end

    context "when random number is greater than 0.6" do
      it "returns 0" do
        allow(feed).to receive(:rand).and_return(0.9)
        expect(feed.score_randomness).to eq 0
      end
    end
  end

  describe "#score_language" do
    context "when article is in a user's preferred language" do
      it "returns a score of 1" do
        expect(feed.score_language(article)).to eq 1
      end
    end

    context "when article is not in user's prferred language" do
      before { article.language = "de" }

      it "returns a score of -10" do
        expect(feed.score_language(article)).to eq(-10)
      end
    end

    context "when article doesn't have a language, assume english" do
      before { article.language = nil }

      it "returns a score of 1" do
        expect(feed.score_language(article)).to eq 1
      end
    end
  end

  describe "#score_followed_tags" do
    let(:tag) { create(:tag) }
    let(:unfollowed_tag) { create(:tag) }

    context "when article includes a followed tag" do
      let(:article) { create(:article, tags: tag.name) }

      before do
        user.follow(tag)
        user.save
        user.follows.last.update(points: 2)
      end

      it "returns the followed tag point value" do
        expect(feed.score_followed_tags(article)).to eq 2
      end
    end

    context "when article includes multiple followed tags" do
      let(:tag2) { create(:tag) }
      let(:article) { create(:article, tags: "#{tag.name}, #{tag2.name}") }

      before do
        user.follow(tag)
        user.follow(tag2)
        user.save
        user.follows.each { |follow| follow.update(points: 2) }
      end

      it "returns the sum of followed tag point values" do
        expect(feed.score_followed_tags(article)).to eq 4
      end
    end

    context "when article includes an unfollowed tag" do
      let(:article) { create(:article, tags: "#{tag.name}, #{unfollowed_tag.name}") }

      before do
        user.follow(tag)
        user.save
      end

      it "doesn't score the unfollowed tag" do
        expect(feed.score_followed_tags(article)).to eq 1
      end
    end

    context "when article doesn't include any followed tags" do
      let(:article) { create(:article, tags: unfollowed_tag.name) }

      it "returns 0" do
        expect(feed.score_followed_tags(article)).to eq 0
      end
    end

    context "when user doesn't follow any tags" do
      it "returns 0" do
        expect(user.cached_followed_tag_names).to be_empty
        expect(feed.score_followed_tags(article)).to eq 0
      end
    end
  end

  describe "#score_experience_level" do
    let(:article) { create(:article, experience_level_rating: 9) }

    context "when user has an experience level" do
      let(:user) { create(:user, experience_level: 3) }

      it "returns negative of (absolute value of the difference between article and user experience) divided by 2" do
        expect(feed.score_experience_level(article)).to eq(-3)
      end
    end

    context "when the user does not have an experience level set" do
      let(:user) { create(:user, experience_level: nil) }

      it "uses a value of 5 for user experience level" do
        expect(feed.score_experience_level(article)).to eq(-2)
      end
    end
  end

  describe "#rank_and_sort_articles" do
    let(:article1) { create(:article) }
    let(:article2) { create(:article) }
    let(:article3) { create(:article) }
    let(:articles) { [article1, article2, article3] }

    context "when number of articles specified" do
      let(:feed) { described_class.new(number_of_articles: 1) }

      it "only returns the requested number of articles" do
        expect(feed.rank_and_sort_articles(articles).size).to eq 1
      end
    end

    it "returns articles in scored order" do
      allow(feed).to receive(:score_single_article).with(article1).and_return(1)
      allow(feed).to receive(:score_single_article).with(article2).and_return(2)
      allow(feed).to receive(:score_single_article).with(article3).and_return(3)

      expect(feed.rank_and_sort_articles(articles)).to eq [article3, article2, article1]
    end
  end
end
