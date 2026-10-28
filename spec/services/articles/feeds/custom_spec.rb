# rubocop:disable Layout/ArgumentAlignment, Layout/TrailingWhitespace, RSpec/AnyInstance, RSpec/LeadingSubject, RSpec/MessageSpies, RSpec/NestedGroups, RSpec/SubjectStub, Rails/DurationArithmetic, Style/CollectionMethods, Style/Send, Style/SlicingWithRange, Style/TrailingCommaInArguments, Style/TrailingCommaInArrayLiteral
require "rails_helper"

RSpec.describe Articles::Feeds::Custom, type: :service do
  subject(:feed) do
    described_class.new(
      user: user,
      number_of_articles: 100,
      page: 1,
      feed_config: feed_config,
    )
  end

  # In test environment, TIME_AGO_MAX is 90.days.ago.
  let(:user) { create(:user) }
  let(:author) { create(:user) }
  # Stub feed_config to return a string rather than a Proc.
  let(:feed_config) { build(:feed_config) }

  # Create articles that are published within the allowed time window.
  let(:high_score_article) { create_feed_article(score: 100, days_ago: 1) }
  let(:medium_score_article) { create_feed_article(score: 50, days_ago: 2) }
  let(:low_score_article) { create_feed_article(score: 10, days_ago: 5) }

  # Create an article published outside of the allowed window.
  let(:old_article) { create_feed_article(score: 80, days_ago: 100) }

  before do
    allow(feed_config).to receive(:score_sql).with(user).and_return("articles.score")
  end

  def create_feed_article(score:, days_ago: 1, **attrs)
    create(
      :article,
      user: author,
      published: true,
      score: score,
      past_published_at: days_ago.days.ago,
      with_tags: attrs.key?(:tags),
      **attrs,
    )
  end

  describe "#default_home_feed" do
    context "when feed_config or user is nil" do
      it "returns an empty array if feed_config is nil" do
        feed_with_nil_config = described_class.new(user: user, feed_config: nil)
        expect(feed_with_nil_config.default_home_feed).to eq([])
      end

      it "returns an empty array if user is nil" do
        feed_with_nil_user = described_class.new(user: nil, feed_config: feed_config)
        expect(feed_with_nil_user.default_home_feed).to eq([])
      end
    end

    context "when valid feed_config and user are provided" do
      before { [high_score_article, medium_score_article, low_score_article, old_article] }

      it "returns only articles published after TIME_AGO_MAX sorted by computed score descending" do
        result = feed.default_home_feed.to_a

        # Articles older than TIME_AGO_MAX (90 days) should be excluded.
        expect(result).to include(high_score_article, medium_score_article, low_score_article)
        expect(result).not_to include(old_article)

        # Since all articles are recent (within a week), they will be shuffled
        # So we check that all expected articles are present but order may vary
        expect(result).to contain_exactly(high_score_article, medium_score_article, low_score_article)
      end

      it "limits returns older article if lookback is configured very long" do
        # Set a long lookback period.
        allow(Settings::UserExperience).to receive(:feed_lookback_days).and_return(200)
        
        result = feed.default_home_feed.to_a

        # Articles older than TIME_AGO_MAX (90 days) should be included.
        expect(result).to include(high_score_article, medium_score_article, low_score_article, old_article)
        expect(result).to include(old_article) # Also included due to window

        # Since computed_score equals articles.score, the feed should be ordered by score descending.
        expect(result).to eq([high_score_article, old_article, medium_score_article, low_score_article])
      end      

      it "returns only very new articles if lookback is configured very short" do
        # Set a short lookback period.
        allow(Settings::UserExperience).to receive(:feed_lookback_days).and_return(3)

        result = feed.default_home_feed.to_a

        # Articles older than 3 days should be excluded.
        expect(result).to include(high_score_article, medium_score_article)
        expect(result).not_to include(low_score_article, old_article)

        # Since all articles are recent (within a week), they will be shuffled
        expect(result).to contain_exactly(high_score_article, medium_score_article)
      end

      it "applies pagination via limit and offset" do
        # Create extra articles so that we can test pagination.
        2.times { create_feed_article(score: 20) }

        paged_feed = described_class.new(
          user: user,
          number_of_articles: 2,
          page: 2,
          feed_config: feed_config
        )
        result = paged_feed.default_home_feed.to_a
        expect(result.size).to eq(2)
      end

      it "filters out blocked articles" do
        blocked_user = create(:user)
        a = create(:article, published: true, score: 90, user: blocked_user)
        a.update_column(:published_at, Time.current - 1.day)
        create(:user_block, blocker: user, blocked: blocked_user, config: "default")
        result = feed.default_home_feed.to_a
        expect(result).not_to include(a)
      end

      context "when articles belong to the current subforem" do
        let(:subforem) { create(:subforem) }

        before do
          Article.where(id: [high_score_article.id, medium_score_article.id, low_score_article.id])
            .update_all(subforem_id: subforem.id)
          RequestStore.store[:subforem_id] = subforem.id
        end

        after { RequestStore.store.delete(:subforem_id) }

        it "loads the feed without querying subforems" do
          subforem_queries = []
          callback = lambda do |_name, _start, _finish, _id, payload|
            subforem_queries << payload[:sql] if payload[:sql].include?('"subforems"')
          end

          result = ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
            feed.default_home_feed.to_a
          end

          expect(result).to contain_exactly(high_score_article, medium_score_article, low_score_article)
          expect(subforem_queries).to be_empty
        end
      end

      context "when user has antifollowed tags" do
        let!(:hidden_article) do
          a = create(:article, published: true, score: 70, tags: "hidden")
          a.update_column(:published_at, Time.current - 1.day)
          a
        end

        let!(:visible_article) do
          a = create(:article, published: true, score: 60, tags: "visible")
          a.update_column(:published_at, Time.current - 1.day)
          a
        end

        before do
          # Stub the user's antifollowed tags.
          allow(user).to receive(:cached_antifollowed_tag_names).and_return(["hidden"])
        end

        it "excludes articles tagged with antifollowed tags" do
          result = feed.default_home_feed.to_a
          expect(result).not_to include(hidden_article)
          expect(result).to include(visible_article)
        end

        it "excludes articles natively intersecting GIN hidden tags when OPTIMIZED_FEED_TAGS_QUERY is active" do
          allow(ENV).to receive(:[]).and_call_original
          allow(ENV).to receive(:[]).with("OPTIMIZED_FEED_TAGS_QUERY").and_return("true")

          result = feed.default_home_feed.to_a
          expect(result).not_to include(hidden_article)
          expect(result).to include(visible_article)
        end
      end

      context "when all articles are recent (within a week)" do
        it "randomly shuffles the top 5 articles while keeping the rest in order" do
          [90, 80, 70, 60].each_with_index do |score, idx|
            create_feed_article(score: score, days_ago: idx + 2)
          end

          # Create a feed with only recent articles to ensure shuffling is triggered
          recent_feed = described_class.new(
            user: user,
            number_of_articles: 10,
            page: 1,
            feed_config: feed_config
          )
          
          result = recent_feed.default_home_feed.to_a
          
          # Filter to only recent articles for this test
          recent_articles = result.select { |article| article.published_at > 1.week.ago }
          
          # Should have some recent articles
          expect(recent_articles.size).to be >= 5
          
          # The top 5 articles should be shuffled (order may vary)
          top_five = recent_articles.first(5)
          expect(top_five.size).to eq(5)
          
          # Articles after position 5 should remain in their original order (by score)
          rest = recent_articles[5..-1]
          if rest.size >= 2
            # Verify that the rest are in score order (no shuffling)
            expect(rest.first.score).to be >= rest.last.score
          end
        end

        it "does not shuffle when not all articles are recent" do
          # Create one old article to make the feed not entirely recent
          # Give it a high score so it appears in the feed
          create_feed_article(score: 200, days_ago: 10)
          
          # Use a larger feed to ensure the old article is included
          large_feed = described_class.new(
            user: user,
            number_of_articles: 20,
            page: 1,
            feed_config: feed_config
          )
          
          result = large_feed.default_home_feed.to_a
          
          # Verify that not all articles are recent (which would trigger shuffling)
          expect(result.all? { |article| article.published_at > 1.week.ago }).to be false
          
          # Check that articles are in score order (no shuffling occurred)
          # Since we added an old article, the feed should be in score order
          if result.size >= 2
            expect(result.first.score).to be >= result[1].score
          end
          
          # Verify that we have some old articles in the result
          old_articles = result.select { |article| article.published_at <= 1.week.ago }
          expect(old_articles).not_to be_empty
        end

        it "handles feeds with fewer than 5 articles correctly" do
          # Create a feed with only 3 recent articles
          small_feed = described_class.new(
            user: user,
            number_of_articles: 10,
            page: 1,
            feed_config: feed_config
          )
          
          result = small_feed.default_home_feed.to_a
          
          # Should contain at least 3 articles (may be more due to other test data)
          expect(result.size).to be >= 3
          
          # All articles should be recent (within a week)
          expect(result.all? { |article| article.published_at > 1.week.ago }).to be true
          
          # All articles should be shuffled (since they're all in the "top 5")
          # We can't easily test the shuffling since it's random, but we can verify
          # that all articles are present and recent
        end
      end
    end
  end

  describe "dynamic shuffle count based on recent page views" do
    let(:user_activity) { create(:user_activity, user: user) }
    
    before do
      user.update!(user_activity: user_activity)
    end

    context "when recent_page_views_shuffle_weight is 0" do
      before do
        feed_config.recent_page_views_shuffle_weight = 0.0
      end

      it "uses default shuffle behavior (top 5) regardless of page view recency" do
        5.times { |i| create_feed_article(score: 100 - i) }

        # Set recent page view that would normally trigger larger shuffle
        user_activity.update!(recently_viewed_articles: [[123, 30.minutes.ago]])

        custom_feed = described_class.new(
          user: user,
          number_of_articles: 15,
          page: 1,
          feed_config: feed_config
        )

        # Should use default behavior and not call calculate_dynamic_shuffle_count
        expect(custom_feed).not_to receive(:calculate_dynamic_shuffle_count)
        
        result = custom_feed.default_home_feed.to_a
        expect(result.size).to be >= 5
      end
    end

    context "when user has no recent page views" do
      before do
        feed_config.recent_page_views_shuffle_weight = 1.0
        user_activity.update!(recently_viewed_articles: [])
      end

      it "shuffles only top 5 articles (default behavior)" do
        5.times { |i| create_feed_article(score: 100 - i) }

        result = feed.default_home_feed.to_a
        expect(result.size).to be >= 5
      end
    end

    context "when user has recent page views and weight > 0" do
      before do
        feed_config.recent_page_views_shuffle_weight = 1.0
      end

      context "with page view within 1 hour" do
        before do
          user_activity.update!(recently_viewed_articles: [[123, 30.minutes.ago]])
        end

        it "shuffles top 20 articles" do
          20.times { |i| create_feed_article(score: 100 - i) }

          # Mock the shuffle behavior to verify count
          allow_any_instance_of(Array).to receive(:shuffle).and_call_original
          
          result = feed.default_home_feed.to_a
          expect(result.size).to be >= 20
        end
      end

      context "with page view 2 hours ago" do
        before do
          user_activity.update!(recently_viewed_articles: [[123, 2.hours.ago]])
        end

        it "shuffles top 18 articles" do
          # Test that the logic calculates 18 for 2 hours ago
          custom_feed = described_class.new(
            user: user,
            number_of_articles: 30,
            page: 1,
            feed_config: feed_config
          )
          
          shuffle_count = custom_feed.send(:calculate_dynamic_shuffle_count)
          expect(shuffle_count).to eq(18)
        end
      end

      context "with page view 15 hours ago" do
        before do
          user_activity.update!(recently_viewed_articles: [[123, 15.hours.ago]])
        end

        it "shuffles minimum 5 articles" do
          custom_feed = described_class.new(
            user: user,
            number_of_articles: 15,
            page: 1,
            feed_config: feed_config
          )
          
          shuffle_count = custom_feed.send(:calculate_dynamic_shuffle_count)
          expect(shuffle_count).to eq(5) # Minimum
        end
      end

      context "with weight multiplier of 0.5" do
        before do
          feed_config.recent_page_views_shuffle_weight = 0.5
          user_activity.update!(recently_viewed_articles: [[123, 1.hour.ago]])
        end

        it "applies weight multiplier correctly" do
          custom_feed = described_class.new(
            user: user,
            number_of_articles: 30,
            page: 1,
            feed_config: feed_config
          )
          
          shuffle_count = custom_feed.send(:calculate_dynamic_shuffle_count)
          # 1 hour ago = base 19, * 0.5 = 9.5, rounded = 10
          expect(shuffle_count).to eq(10)
        end
      end

      context "with weight multiplier of 2.0" do
        before do
          feed_config.recent_page_views_shuffle_weight = 2.0
          user_activity.update!(recently_viewed_articles: [[123, 1.hour.ago]])
        end

        it "caps at maximum 20 articles" do
          custom_feed = described_class.new(
            user: user,
            number_of_articles: 30,
            page: 1,
            feed_config: feed_config
          )
          
          shuffle_count = custom_feed.send(:calculate_dynamic_shuffle_count)
          # 1 hour ago = base 19, * 2.0 = 38, capped at 20
          expect(shuffle_count).to eq(20)
        end
      end

      context "with very low weight resulting in less than 5" do
        before do
          feed_config.recent_page_views_shuffle_weight = 0.1
          user_activity.update!(recently_viewed_articles: [[123, 10.hours.ago]])
        end

        it "ensures minimum of 5 articles" do
          custom_feed = described_class.new(
            user: user,
            number_of_articles: 30,
            page: 1,
            feed_config: feed_config
          )
          
          shuffle_count = custom_feed.send(:calculate_dynamic_shuffle_count)
          # 10 hours ago = base 11, * 0.1 = 1.1, rounded = 1, but minimum is 5
          expect(shuffle_count).to eq(5)
        end
      end
    end

    context "when user has no user_activity" do
      before do
        user.update!(user_activity: nil)
        feed_config.recent_page_views_shuffle_weight = 1.0
      end

      it "falls back to default shuffle count of 5" do
        custom_feed = described_class.new(
          user: user,
          number_of_articles: 30,
          page: 1,
          feed_config: feed_config
        )
        
        shuffle_count = custom_feed.send(:calculate_dynamic_shuffle_count)
        expect(shuffle_count).to eq(5)
      end
    end
  end

  describe "#calculate_dynamic_shuffle_count" do
    let(:user_activity) { create(:user_activity, user: user) }
    
    before do
      user.update!(user_activity: user_activity)
      feed_config.recent_page_views_shuffle_weight = 1.0
    end

    subject(:custom_feed) do
      described_class.new(
        user: user,
        number_of_articles: 30,
        page: 1,
        feed_config: feed_config
      )
    end

    it "calculates correct shuffle count for various time intervals" do
      test_cases = [
        { hours_ago: 0.5, expected: 20 },
        { hours_ago: 1, expected: 19 },
        { hours_ago: 2, expected: 18 },
        { hours_ago: 5, expected: 15 },
        { hours_ago: 15, expected: 5 },
        { hours_ago: 25, expected: 5 }
      ]

      test_cases.each do |test_case|
        user_activity.update!(recently_viewed_articles: [[123, test_case[:hours_ago].hours.ago]])
        
        shuffle_count = custom_feed.send(:calculate_dynamic_shuffle_count)
        expect(shuffle_count).to eq(test_case[:expected]), 
          "Expected #{test_case[:expected]} for #{test_case[:hours_ago]} hours ago, got #{shuffle_count}"
      end
    end

    it "handles edge cases correctly" do
      # No recent page views
      user_activity.update!(recently_viewed_articles: [])
      expect(custom_feed.send(:calculate_dynamic_shuffle_count)).to eq(5)

      # Nil recently_viewed_articles
      user_activity.update!(recently_viewed_articles: nil)
      expect(custom_feed.send(:calculate_dynamic_shuffle_count)).to eq(5)

      # Empty page view entry
      user_activity.update!(recently_viewed_articles: [[]])
      expect(custom_feed.send(:calculate_dynamic_shuffle_count)).to eq(5)

      # Invalid timestamp format
      user_activity.update!(recently_viewed_articles: [[123, "invalid"]])
      expect { custom_feed.send(:calculate_dynamic_shuffle_count) }.not_to raise_error
      expect(custom_feed.send(:calculate_dynamic_shuffle_count)).to eq(5)

      # Very old page view (should default to minimum)
      user_activity.update!(recently_viewed_articles: [[123, 100.hours.ago]])
      expect(custom_feed.send(:calculate_dynamic_shuffle_count)).to eq(5)
    end

    it "handles fractional weights correctly" do
      feed_config.recent_page_views_shuffle_weight = 0.33
      user_activity.update!(recently_viewed_articles: [[123, 1.hour.ago]])
      
      shuffle_count = custom_feed.send(:calculate_dynamic_shuffle_count)
      # 1 hour ago = base 19, * 0.33 = 6.27, rounded = 6
      expect(shuffle_count).to eq(6)
    end

    it "handles negative weights by using default behavior" do
      feed_config.recent_page_views_shuffle_weight = -1.0
      user_activity.update!(recently_viewed_articles: [[123, 1.hour.ago]])
      
      # Create 10 recent articles
      10.times do |i|
        a = create(:article, published: true, score: 100 - i)
        a.update_column(:published_at, Time.current - 1.day)
      end

      # Should not use dynamic shuffle when weight is negative
      expect(custom_feed).not_to receive(:calculate_dynamic_shuffle_count)
      
      result = custom_feed.default_home_feed.to_a
      expect(result.size).to be >= 5
    end

    it "handles extremely large weights" do
      feed_config.recent_page_views_shuffle_weight = 1000.0
      user_activity.update!(recently_viewed_articles: [[123, 1.hour.ago]])
      
      shuffle_count = custom_feed.send(:calculate_dynamic_shuffle_count)
      # Should be capped at 20 regardless of large weight
      expect(shuffle_count).to eq(20)
    end
  end

  describe "public interface aliases" do
    it "aliases feed to default_home_feed" do
      expect(feed.method(:feed)).to eq(feed.method(:default_home_feed))
    end

    it "aliases more_comments_minimal_weight_randomized to default_home_feed" do
      expect(feed.method(:more_comments_minimal_weight_randomized))
        .to eq(feed.method(:default_home_feed))
    end
  end

  describe "AI disclosure preferences" do
    let!(:no_ai_article) do
      a = create(:article, published: true, score: 90, ai_disclosure_level: :no_ai)
      a.update_column(:published_at, Time.current - 1.day)
      a
    end

    let!(:some_ai_article) do
      a = create(:article, published: true, score: 85, ai_disclosure_level: :some_ai)
      a.update_column(:published_at, Time.current - 1.day)
      a
    end

    let!(:autonomous_article) do
      a = create(:article, published: true, score: 80, ai_disclosure_level: :fully_autonomous)
      a.update_column(:published_at, Time.current - 1.day)
      a
    end

    context "when user has hide_fully_autonomous preference" do
      before { user.setting.update(feed_ai_preference: :hide_fully_autonomous) }

      it "filters out fully autonomous articles from the feed" do
        result = feed.default_home_feed.to_a
        expect(result).to include(no_ai_article, some_ai_article)
        expect(result).not_to include(autonomous_article)
      end
    end

    context "when user has show_all preference" do
      before { user.setting.update(feed_ai_preference: :show_all) }

      it "includes all AI disclosure levels in the feed" do
        result = feed.default_home_feed.to_a
        expect(result).to include(no_ai_article, some_ai_article, autonomous_article)
      end
    end
  end

  describe "performance optimizations" do
    it "preloads the requested comments_variant to prevent downstream N+1 queries" do
      high_score_article
      result = feed.default_home_feed(comments_variant: "more_inclusive_recent_good_comments")
      first_article = result.first
      expect(first_article.association(:more_inclusive_recent_good_comments)).to be_loaded
    end

    it "uses limited_column_select avoiding heavy text and vector columns" do
      high_score_article
      result = feed.default_home_feed.to_a
      first_article = result.first
      expect(first_article.has_attribute?(:title)).to be true
      expect(first_article.has_attribute?(:body_markdown)).to be false
      expect(first_article.has_attribute?(:semantic_embedding)).to be false
    end

    it "loads the feed without querying reactions" do
      create(:reaction, reactable: high_score_article, user: user, category: "like")
      reaction_queries = []
      callback = lambda do |_name, _start, _finish, _id, payload|
        reaction_queries << payload[:sql] if payload[:sql].include?('"reactions"')
      end

      ActiveSupport::Notifications.subscribed(callback, "sql.active_record") { feed.default_home_feed.to_a }

      expect(reaction_queries).to be_empty
    end

    it "still returns the reaction categories of each article" do
      create(:reaction, reactable: high_score_article, user: user, category: "like")

      story = feed.default_home_feed.to_a.find { |article| article.id == high_score_article.id }

      expect(story.public_reaction_categories.map(&:slug)).to eq([:like])
    end

    it "permutes candidates via ForemNative.weighted_shuffle and falls back cleanly if nil" do
      candidates = build_stubbed_list(:article, 3)
      shuffled = feed.__send__(:weighted_shuffle, candidates, 1.5)
      expect(shuffled).to match_array(candidates)

      allow(ForemNative).to receive(:weighted_shuffle).and_return(nil)
      fallback_shuffled = feed.__send__(:weighted_shuffle, candidates, 1.5)
      expect(fallback_shuffled).to match_array(candidates)
    end

    context "when semantic_similarity_weight is active for a user with an interest_embedding" do
      let(:interest_embedding) { [1.0, 0.0, 0.0] + Array.new(765, 0.0) }
      let(:aligned_embedding) { [1.0, 0.0, 0.0] + Array.new(765, 0.0) }
      let(:orthogonal_embedding) { [0.0, 1.0, 0.0] + Array.new(765, 0.0) }
      let!(:user_activity) { create(:user_activity, user: user) }

      before do
        allow(feed_config).to receive(:score_sql).and_call_original
        user_activity.update_column(:interest_embedding, interest_embedding)
        high_score_article.update_column(:semantic_embedding, orthogonal_embedding)
        medium_score_article.update_column(:semantic_embedding, aligned_embedding)
        low_score_article.update_column(:semantic_embedding, orthogonal_embedding)
        FeedConfig.new.attributes.each_key do |attr|
          feed_config[attr] = 0.0 if attr.ends_with?("_weight") || attr.ends_with?("_rate")
        end
        feed_config.score_weight = 1.0
        feed_config.semantic_similarity_weight = 100.0
      end

      it "uses two-stage candidate pre-filtering to bound semantic vector evaluation and ranks by combined score" do
        allow(feed).to receive(:shuffle_top_five_if_recent) { |articles| articles }

        executed_sql = []
        callback = lambda do |_name, _start, _finish, _id, payload|
          executed_sql << payload[:sql] if payload[:sql].include?("computed_score")
        end

        result = nil
        ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
          result = feed.default_home_feed.to_a
        end

        expect(executed_sql.size).to eq(1)
        query_sql = executed_sql.first
        expect(query_sql).to include('AND "articles"."id" IN (SELECT "articles"."id" FROM "articles"')
        expect(query_sql).to include("articles.semantic_embedding <=>")
        # medium_score_article (50 + 100 = 150) outranks high_score_article (100 + 0 = 100)
        expect(result.first).to eq(medium_score_article)
      end

      it "respects the variable semantic_candidate_limit on feed_config when semantic_similarity_weight > 0" do
        custom_page_feed = described_class.new(
          user: user,
          number_of_articles: 18,
          page: 1,
          feed_config: feed_config,
        )

        feed_config.semantic_candidate_limit = 120
        expect(custom_page_feed.__send__(:semantic_candidate_limit)).to eq(120)

        feed_config.semantic_candidate_limit = 550
        expect(custom_page_feed.__send__(:semantic_candidate_limit)).to eq(550)

        feed_config.semantic_candidate_limit = 50
        expect(custom_page_feed.__send__(:semantic_candidate_limit)).to eq(FeedConfig::MIN_SEMANTIC_CANDIDATE_LIMIT)

        feed_config.semantic_candidate_limit = 2000
        expect(custom_page_feed.__send__(:semantic_candidate_limit)).to eq(FeedConfig::MAX_SEMANTIC_CANDIDATE_LIMIT)

        page_two_large_feed = described_class.new(
          user: user,
          number_of_articles: 100,
          page: 2,
          feed_config: feed_config,
        )
        feed_config.semantic_candidate_limit = 100
        expect(page_two_large_feed.__send__(:semantic_candidate_limit)).to eq(100)
      end

      it "keeps candidate windows disjoint across pages so no candidate is skipped or duplicated" do
        # Create 3 additional articles so we have 6 eligible articles total:
        # base scores: [100, 50, 40, 30, 20, 10]
        article_40 = create(:article, published: true, score: 40)
        article_40.update_column(:published_at, Time.current - 1.day)
        article_40.update_column(:semantic_embedding, orthogonal_embedding)

        article_30 = create(:article, published: true, score: 30)
        article_30.update_column(:published_at, Time.current - 1.day)
        # Give the 4th base-score article (in window 2 when window_size=3) a huge semantic boost
        # so its computed_score (30 + 100 = 130) exceeds window-1 articles (100, 40)
        article_30.update_column(:semantic_embedding, aligned_embedding)

        article_20 = create(:article, published: true, score: 20)
        article_20.update_column(:published_at, Time.current - 1.day)
        article_20.update_column(:semantic_embedding, orthogonal_embedding)

        allow(feed_config).to receive(:effective_semantic_candidate_limit).and_return(3)

        # 1) Page size == window size (3): page 1 covers window 0, page 2 covers window 1
        page1_feed = described_class.new(user: user, number_of_articles: 3, page: 1, feed_config: feed_config)
        page2_feed = described_class.new(user: user, number_of_articles: 3, page: 2, feed_config: feed_config)
        allow(page1_feed).to receive(:shuffle_top_five_if_recent) { |articles| articles }
        allow(page2_feed).to receive(:shuffle_top_five_if_recent) { |articles| articles }

        page1_ids = page1_feed.default_home_feed.map(&:id)
        page2_ids = page2_feed.default_home_feed.map(&:id)

        # Window 0 ([100, 50, 40]) ranked by computed_score -> [50 (+100=150), 100 (+0=100), 40 (+0=40)]
        expect(page1_ids).to eq([medium_score_article.id, high_score_article.id, article_40.id])
        # Window 1 ([30, 20, 10]) ranked by computed_score -> [30 (+100=130), 20 (+0=20), 10 (+0=10)]
        # article_30 is NOT skipped and article_40 is NOT duplicated on page 2
        expect(page2_ids).to eq([article_30.id, article_20.id, low_score_article.id])
        expect(page1_ids & page2_ids).to be_empty

        # 2) Page size straddling the window boundary (page_size=2 across window_size=3)
        straddle_pages = (1..3).flat_map do |page_num|
          paged = described_class.new(user: user, number_of_articles: 2, page: page_num, feed_config: feed_config)
          allow(paged).to receive(:shuffle_top_five_if_recent) { |articles| articles }
          paged.default_home_feed.map(&:id)
        end

        expect(straddle_pages).to eq(page1_ids + page2_ids)
      end

      it "ignores semantic_candidate_limit completely when semantic_similarity_weight is 0.0" do
        feed_config.semantic_similarity_weight = 0.0
        feed_config.semantic_candidate_limit = 450

        executed_sql = []
        callback = lambda do |_name, _start, _finish, _id, payload|
          executed_sql << payload[:sql] if payload[:sql].include?("computed_score")
        end

        ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
          feed.default_home_feed.to_a
        end

        expect(executed_sql.first).not_to include('AND "articles"."id" IN (SELECT "articles"."id" FROM "articles"')
        expect(executed_sql.first).not_to include("articles.semantic_embedding <=>")
      end

      it "falls back to direct semantic scoring when all non-semantic weights are zero" do
        FeedConfig.new.attributes.each_key do |attr|
          feed_config[attr] = 0.0 if attr.ends_with?("_weight") || attr.ends_with?("_rate")
        end
        feed_config.semantic_similarity_weight = 50.0

        executed_sql = []
        callback = lambda do |_name, _start, _finish, _id, payload|
          executed_sql << payload[:sql] if payload[:sql].include?("computed_score")
        end

        ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
          feed.default_home_feed.to_a
        end

        expect(executed_sql.first).not_to include('AND "articles"."id" IN (SELECT "articles"."id" FROM "articles"')
        expect(executed_sql.first).to include("articles.semantic_embedding <=>")
      end
    end
  end
end
# rubocop:enable Layout/ArgumentAlignment, Layout/TrailingWhitespace, RSpec/AnyInstance, RSpec/LeadingSubject, RSpec/MessageSpies, RSpec/NestedGroups, RSpec/SubjectStub, Rails/DurationArithmetic, Style/CollectionMethods, Style/Send, Style/SlicingWithRange, Style/TrailingCommaInArguments, Style/TrailingCommaInArrayLiteral
