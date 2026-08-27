require "rails_helper"

RSpec.describe Articles::Feeds::Basic, type: :service do
  let(:second_user) { create(:user) }
  let(:unique_tag_name) { "foo" }
  let!(:article) { create(:article, hotness_score: 10) }
  let!(:hot_story) do
    create(:article, :past, hotness_score: 1000, score: 1000, past_published_at: 3.hours.ago, user_id: second_user.id)
  end
  let!(:old_story) { create(:article, :past, hotness_score: 500, past_published_at: 3.days.ago, tags: unique_tag_name) }
  let!(:low_scoring_article) { create(:article, score: -1000) }
  let!(:month_old_story) { create(:article, :past, past_published_at: 1.month.ago) } # rubocop:disable RSpec/LetSetup

  let(:feed) { described_class.new(user: user, number_of_articles: 100, page: 1) }

  context "without a user" do
    let(:user) { nil }

    it "returns articles with score above 0 in order of hotness score" do
      result = feed.feed
      expect(result.first).to eq hot_story
      expect(result.second).to eq old_story
      expect(result.third).to eq article
      expect(result).not_to include(low_scoring_article)
    end
  end

  context "with a user" do
    let(:user) { create(:user) }

    it "returns articles with score above 0 sorted by user preference scores" do
      user.follow(old_story.user)
      old_story_tag = Tag.find_by(name: unique_tag_name)
      user.follow(old_story_tag)

      result = feed.feed
      expect(result.first).to eq old_story
      expect(result.second).to eq hot_story
      expect(result.third).to eq article
      expect(result).not_to include(low_scoring_article)
    end

    it "does not load blocked articles" do
      create(:user_block, blocker: user, blocked: second_user, config: "default")
      result = feed.feed
      expect(result).not_to include(hot_story)
    end

    context "when user has hidden tags" do
      let!(:hidden) { create(:article, tags: "notme") }
      let!(:visible) { create(:article, tags: "surewhynot") }

      before do
        antitag = ActsAsTaggableOn::Tag.find_by(name: "notme") || create(:tag, name: "notme")
        user
          .follows_by_type("ActsAsTaggableOn::Tag")
          .create! followable: antitag, explicit_points: -5.0
      end

      it "does not return articles with tags the user has hidden" do
        result = feed.feed
        expect(result).not_to include(hidden)
        expect(result).to include(visible)
      end
    end

    context "with AI disclosure preferences" do
      let!(:no_ai_post) { create(:article, hotness_score: 50, ai_disclosure_level: :no_ai) }
      let!(:some_ai_post) { create(:article, hotness_score: 50, ai_disclosure_level: :some_ai) }
      let!(:autonomous_post) { create(:article, hotness_score: 50, ai_disclosure_level: :fully_autonomous) }

      context "when feed_ai_preference is show_all" do
        before { user.setting.update(feed_ai_preference: :show_all) }

        it "includes all articles" do
          result = feed.feed
          expect(result).to include(no_ai_post, some_ai_post, autonomous_post)
        end
      end

      context "when feed_ai_preference is minimize_ai" do
        before { user.setting.update(feed_ai_preference: :minimize_ai) }

        it "ranks human/no_ai content higher than AI disclosed content with same baseline" do
          result = feed.feed
          expect(result.index(no_ai_post)).to be < result.index(some_ai_post)
          expect(result.index(some_ai_post)).to be < result.index(autonomous_post)
        end
      end

      context "when feed_ai_preference is hide_fully_autonomous" do
        before { user.setting.update(feed_ai_preference: :hide_fully_autonomous) }

        it "completely excludes fully autonomous articles" do
          result = feed.feed
          expect(result).to include(no_ai_post, some_ai_post)
          expect(result).not_to include(autonomous_post)
        end
      end
    end
  end
end
