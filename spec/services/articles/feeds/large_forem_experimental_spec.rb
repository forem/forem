require "rails_helper"

RSpec.describe Articles::Feeds::LargeForemExperimental, type: :service do
  let(:user) { create(:user, :without_profile, profile_image: nil) }
  let(:second_user) { create(:user, :without_profile, profile_image: nil) }
  let(:feed) { described_class.new(user: user, number_of_articles: 100, page: 1) }
  let!(:article) { create(:article, user: user, with_tags: false) }
  let!(:hot_story) do
    create(:article, :past, hotness_score: 1000, score: 1000, past_published_at: 3.hours.ago, user: second_user,
                            with_tags: false)
  end
  let!(:old_story) { create(:article, :past, past_published_at: 3.days.ago, user: user, with_tags: false) }
  let!(:low_scoring_article) { create(:article, score: -1000, user: user, with_tags: false) }

  describe "#featured_story_and_default_home_feed" do
    let(:default_feed) { feed.featured_story_and_default_home_feed }
    let(:featured_story) { default_feed.first }
    let(:stories) { default_feed.second }
    let!(:min_score_article) { create(:article, score: 0, user: user, with_tags: false) }

    before do
      article.update(published_at: 1.week.ago)
      allow(Settings::UserExperience).to receive(:home_feed_minimum_score).and_return(0)
    end

    it "returns a featured article and correctly scored other articles", :aggregate_failures do
      expect(stories).to be_a(Array)
      expect(featured_story).to eq hot_story
      expect(stories).not_to include(low_scoring_article)
      expect(stories).to include(min_score_article)
    end

    it "includes favorited articles even if their score is below the home feed minimum score" do
      favorited_low_score_article = create(:article, score: -100, favorited_by_user: create(:user),
                                                     favorited_at: Time.current)
      expect(stories).to include(favorited_low_score_article)
    end

    it "includes featured articles even if their score is below the home feed minimum score" do
      featured_low_score_article = create(:article, score: -100, featured: true)
      expect(stories).to include(featured_low_score_article)
    end

    context "when user logged in" do
      let(:result) { feed.featured_story_and_default_home_feed(user_signed_in: true) }
      let(:featured_story) { result.first }
      let(:stories) { result.second }

      it "only includes stories" do
        expect(stories).to include(old_story)
        expect(stories).to include(article)
        expect(stories).to include(hot_story)
      end

      it "does not load blocked articles" do
        create(:user_block, blocker: user, blocked: second_user, config: "default")
        expect(result).not_to include(hot_story)
      end
    end

    [true, false].each do |signed_in|
      it "loads the feed without querying subforems when user_signed_in is #{signed_in}", :aggregate_failures do
        subforem = create(:subforem)
        hot_story.update_column(:subforem_id, subforem.id)
        RequestStore.store[:subforem_id] = subforem.id

        subforem_queries = []
        callback = lambda do |_name, _start, _finish, _id, payload|
          subforem_queries << payload[:sql] if payload[:sql].include?('"subforems"')
        end
        result = ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
          feed.featured_story_and_default_home_feed(user_signed_in: signed_in)
        end

        expect(result.second).to include(hot_story)
        expect(subforem_queries).to be_empty
      ensure
        RequestStore.store.delete(:subforem_id)
      end
    end

    context "when ranking is true" do
      it "performs article ranking" do
        allow(feed).to receive(:rank_and_sort_articles).and_call_original
        feed.featured_story_and_default_home_feed(ranking: true)
        expect(feed).to have_received(:rank_and_sort_articles)
      end
    end

    context "when ranking is false" do
      it "does not perform article ranking" do
        allow(feed).to receive(:rank_and_sort_articles).and_call_original
        feed.featured_story_and_default_home_feed(ranking: false)
        expect(feed).not_to have_received(:rank_and_sort_articles)
      end
    end

    context "when ranking not passed" do
      it "performs article ranking" do
        allow(feed).to receive(:rank_and_sort_articles).and_call_original
        feed.featured_story_and_default_home_feed
        expect(feed).to have_received(:rank_and_sort_articles)
      end
    end
  end

  describe "#default_home_feed" do
    let!(:new_story) { create(:article, published_at: 10.minutes.ago, score: 10) }

    context "when user is not logged in" do
      let(:stories) { feed.default_home_feed(user_signed_in: false) }

      before { article.update(published_at: 1.week.ago) }

      it "returns array of high scoring articles" do
        expect(stories).to be_a(Array)
        expect(stories.first).to be_a(Article)
        expect(stories).not_to include(low_scoring_article)
      end
    end

    context "when user logged in" do
      let(:stories) { feed.default_home_feed(user_signed_in: true) }

      it "includes stories" do
        expect(stories).to include(old_story)
        expect(stories).to include(new_story)
      end
    end

    context "when experiment is running" do
      it "works with every variant" do
        # Basic test to see that these all work.
        %i[base
           base_with_more_articles
           only_followed_tags
           top_articles_since_last_pageview_3_days_max
           top_articles_since_last_pageview_7_days_max
           combination_only_tags_followed_and_top_max_7_days].each do |experiment|
          create(:field_test_membership,
                 experiment: experiment, variant: "base", participant_id: user.id)
          stories = feed.default_home_feed(user_signed_in: true)
          expect(stories.size).to be > 0
        end
      end
    end
  end

  describe "more_comments_minimal_weight_randomized" do
    it "returns articles" do
      new_story = create(:article, published_at: 10.minutes.ago, score: 10)
      stories = feed.more_comments_minimal_weight_randomized
      expect(stories).to include(old_story)
      expect(stories).to include(new_story)
    end
  end

  describe "#rank_and_sort_articles" do
    let(:article1) { build_stubbed(:article) }
    let(:article2) { build_stubbed(:article) }
    let(:article3) { build_stubbed(:article) }
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

  describe ".globally_hot_articles" do
    let!(:recently_published_article) { create(:article, :past, past_published_at: 3.hours.ago) }
    let(:globally_hot_articles) { feed.globally_hot_articles(true).second }

    it "returns hot recent stories" do
      expect(globally_hot_articles).not_to be_empty
      expect(globally_hot_articles).to include(recently_published_article)
    end

    context "when low number of hot stories and no recently published articles" do
      before do
        Article.delete_all
        create(:article, :past, hotness_score: 1000, score: 1000, past_published_at: 3.hours.ago)
      end

      # This test handles a situation in which there are a low number of hot or new stories, and the user is logged in.
      # Previously the offset factor could result in zero stories being returned sometimes.

      # We manually called `feed.globally_hot_articles` here because `let` caches it!
      it "still returns articles" do
        empty_feed = false
        5.times do
          if feed.globally_hot_articles(true).second.empty?
            empty_feed = true
            break
          end
        end
        expect(empty_feed).to be false
      end
    end

    context "when no hot stories or recently published articles" do
      before do
        Article.delete_all
        create(:article, :past, hotness_score: 0, score: 0, past_published_at: 3.days.ago)
      end

      it "still returns articles" do
        expect(globally_hot_articles).not_to be_empty
      end
    end

    [true, false].each do |signed_in|
      it "loads the feed without querying reactions when user_signed_in is #{signed_in}" do
        create(:reaction, reactable: hot_story, category: "like")
        reaction_queries = []
        callback = lambda do |_name, _start, _finish, _id, payload|
          reaction_queries << payload[:sql] if payload[:sql].include?('"reactions"')
        end

        ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
          feed.globally_hot_articles(signed_in).second.to_a
        end

        expect(reaction_queries).to be_empty
      end
    end

    it "still returns the reaction categories of each article" do
      create(:reaction, reactable: hot_story, category: "like")

      story = feed.globally_hot_articles(false).second.detect { |result| result.id == hot_story.id }

      expect(story.public_reaction_categories.map(&:slug)).to eq([:like])
    end
  end

  describe "AI disclosure preferences" do
    let!(:no_ai_article) do
      create(:article, :past, past_published_at: 1.hour.ago, ai_disclosure_level: :no_ai,
                              user: user, with_tags: false)
    end
    let!(:autonomous_article) do
      create(:article, :past, past_published_at: 1.hour.ago, ai_disclosure_level: :fully_autonomous,
                              user: user, with_tags: false)
    end

    context "when user has hide_fully_autonomous preference" do
      before { user.setting.update(feed_ai_preference: :hide_fully_autonomous) }

      it "filters out fully autonomous articles from globally_hot_articles" do
        _featured, stories = feed.globally_hot_articles(true)
        expect(stories).to include(no_ai_article)
        expect(stories).not_to include(autonomous_article)
      end
    end

    context "when user has show_all preference" do
      before { user.setting.update(feed_ai_preference: :show_all) }

      it "includes all AI disclosure levels in globally_hot_articles" do
        _featured, stories = feed.globally_hot_articles(true)
        expect(stories).to include(no_ai_article, autonomous_article)
      end
    end
  end
end
