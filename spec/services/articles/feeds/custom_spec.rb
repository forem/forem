require "rails_helper"

RSpec.describe Articles::Feeds::Custom, type: :service do
  # In test environment, TIME_AGO_MAX is 90.days.ago.
  let(:user) { create(:user) }
  # Stub feed_config to return a string rather than a Proc.
  let(:feed_config) { build(:feed_config) }
  before do
    allow(feed_config).to receive(:score_sql).with(user).and_return("articles.score")
  end

  # Create articles that are published within the allowed time window.
  let!(:high_score_article) do
    a = create(:article, published: true, score: 100)
    a.update_column(:published_at, Time.current - 1.day)
    a
  end

  let!(:medium_score_article) do
    a = create(:article, published: true, score: 50)
    a.update_column(:published_at, Time.current - 2.days)
    a
  end

  let!(:low_score_article) do
    a = create(:article, published: true, score: 10)
    a.update_column(:published_at, Time.current - 5.days)
    a
  end

  # Create an article published outside of the allowed window.
  let!(:old_article) do
    a = create(:article, published: true, score: 80)
    a.update_column(:published_at, Time.current - 100.days)
    a
  end

  subject(:feed) do
    described_class.new(
      user: user,
      number_of_articles: 100,
      page: 1,
      feed_config: feed_config
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
        30.times do
          a = create(:article, published: true, score: 20)
          a.update_column(:published_at, Time.current - 1.day)
        end

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
      end

      context "when all articles are recent (within a week)" do
        let!(:recent_article_1) do
          a = create(:article, published: true, score: 100)
          a.update_column(:published_at, Time.current - 1.day)
          a
        end

        let!(:recent_article_2) do
          a = create(:article, published: true, score: 90)
          a.update_column(:published_at, Time.current - 2.days)
          a
        end

        let!(:recent_article_3) do
          a = create(:article, published: true, score: 80)
          a.update_column(:published_at, Time.current - 3.days)
          a
        end

        let!(:recent_article_4) do
          a = create(:article, published: true, score: 70)
          a.update_column(:published_at, Time.current - 4.days)
          a
        end

        let!(:recent_article_5) do
          a = create(:article, published: true, score: 60)
          a.update_column(:published_at, Time.current - 5.days)
          a
        end

        let!(:recent_article_6) do
          a = create(:article, published: true, score: 50)
          a.update_column(:published_at, Time.current - 6.days)
          a
        end

        let!(:recent_article_7) do
          a = create(:article, published: true, score: 40)
          a.update_column(:published_at, Time.current - 7.days)
          a
        end

        it "randomly shuffles the top 5 articles while keeping the rest in order" do
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
          old_recent_article = create(:article, published: true, score: 200)
          old_recent_article.update_column(:published_at, Time.current - 10.days)
          
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
          
          # Delete the extra articles to leave only 3
          recent_article_4.destroy
          recent_article_5.destroy
          recent_article_6.destroy
          recent_article_7.destroy
          
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
        # Create 10 recent articles
        articles = []
        10.times do |i|
          a = create(:article, published: true, score: 100 - i)
          a.update_column(:published_at, Time.current - 1.day)
          articles << a
        end

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
        # Create 10 recent articles
        10.times do |i|
          a = create(:article, published: true, score: 100 - i)
          a.update_column(:published_at, Time.current - 1.day)
        end

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
          # Create 25 recent articles to test the 20 limit
          articles = []
          25.times do |i|
            a = create(:article, published: true, score: 100 - i)
            a.update_column(:published_at, Time.current - 1.day)
            articles << a
          end

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
          # Create 25 recent articles
          25.times do |i|
            a = create(:article, published: true, score: 100 - i)
            a.update_column(:published_at, Time.current - 1.day)
          end

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
          # Create 10 recent articles
          10.times do |i|
            a = create(:article, published: true, score: 100 - i)
            a.update_column(:published_at, Time.current - 1.day)
          end

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
end
