require "rails_helper"

NON_DEFAULT_EXPERIMENTS = %i[
  default_home_feed_with_more_randomness_experiment
  mix_default_and_more_random_experiment
  more_tag_weight_experiment
  more_tag_weight_more_random_experiment
  more_comments_experiment
  more_experience_level_weight_experiment
  more_tag_weight_randomized_at_end_experiment
  more_experience_level_weight_randomized_at_end_experiment
  more_comments_randomized_at_end_experiment
  mix_of_everything_experiment
].freeze

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

      it "only includes stories" do
        expect(stories).to include(old_story)
        expect(stories).to include(article)
        expect(stories).to include(hot_story)
      end
    end

    context "when ranking is true" do
      it "performs article ranking" do
        allow(feed).to receive(:rank_and_sort_articles).and_call_original
        feed.default_home_feed_and_featured_story(ranking: true)
        expect(feed).to have_received(:rank_and_sort_articles)
      end
    end

    context "when ranking is false" do
      it "does not perform article ranking" do
        allow(feed).to receive(:rank_and_sort_articles).and_call_original
        feed.default_home_feed_and_featured_story(ranking: false)
        expect(feed).not_to have_received(:rank_and_sort_articles)
      end
    end

    context "when ranking not passed" do
      it "performs article ranking" do
        allow(feed).to receive(:rank_and_sort_articles).and_call_original
        feed.default_home_feed_and_featured_story
        expect(feed).to have_received(:rank_and_sort_articles)
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

      it "includes stories " do
        expect(stories).to include(old_story)
        expect(stories).to include(new_story)
      end
    end
  end

  describe "all non-default experiments" do
    it "returns articles for all experiments" do
      new_story = create(:article, published_at: 10.minutes.ago, score: 10)
      NON_DEFAULT_EXPERIMENTS.each do |method|
        stories = feed.public_send(method)
        expect(stories).to include(old_story)
        expect(stories).to include(new_story)
      end
    end
  end

  describe "#more_comments_experiment" do
    let(:article_with_one_comment) { create(:article) }
    let(:article_with_five_comments) { create(:article) }
    let(:stories) { feed.more_comments_experiment }

    before do
      create(:comment, user: user, commentable: article_with_one_comment)
      create_list(:comment, 5, user: user, commentable: article_with_five_comments)
      article_with_one_comment.update_score
      article_with_five_comments.update_score
      article_with_one_comment.reload
      article_with_five_comments.reload
    end

    it "ranks articles with more comments higher" do
      expect(stories[0]).to eq article_with_five_comments
    end
  end

  describe ".find_featured_story" do
    let(:featured_story) { described_class.find_featured_story(stories) }

    context "when passed an ActiveRecord collection" do
      let(:stories) { Article.all }

      it "returns first article with a main image" do
        expect(featured_story.main_image).not_to be_nil
      end
    end

    context "when passed an array" do
      let(:stories) { Article.all.to_a }

      it "returns first article with a main image" do
        expect(featured_story.main_image).not_to be_nil
      end
    end

    context "when passed collection without any articles" do
      let(:stories) { [] }

      it "returns an new, empty Article object" do
        expect(featured_story.main_image).to be_nil
        expect(featured_story.id).to be_nil
      end
    end
  end

  describe "#find_featured_story" do
    it "calls the class method" do
      allow(described_class).to receive(:find_featured_story)
      feed.find_featured_story([])
      expect(described_class).to have_received(:find_featured_story)
    end
  end
end
