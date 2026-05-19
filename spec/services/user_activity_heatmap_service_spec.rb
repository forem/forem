require "rails_helper"

RSpec.describe UserActivityHeatmapService do
  let(:user) { create(:user) }
  let(:today) { Date.current }
  let(:service) { described_class.new(user, end_date: today) }

  # Articles validate against backdated published_at (>15 min in the past).
  # The heatmap, by design, asks about the past, so tests need to put records
  # at historical timestamps. We bypass validation with `update_columns` after
  # the record is created so the date assertions exercise the actual SQL
  # grouping rather than the validator.
  def backdate_article(article, published_at)
    article.update_columns(published_at: published_at)
    article
  end

  # The service buckets by DATE(timestamp) against UTC-stored values. Using
  # `Date#beginning_of_day - N.days` lands at midnight which becomes the
  # previous calendar day in any TZ ahead of UTC and trips off-by-one
  # assertions in CI. Anchor backdates at noon UTC so DATE() always returns
  # the intended calendar day regardless of zone.
  def noon_utc_for(date)
    Time.utc(date.year, date.month, date.day, 12)
  end

  describe "#call" do
    it "returns a fully-padded 365-day window" do
      payload = service.call

      expect(payload[:start_date]).to eq((today - 364.days).iso8601)
      expect(payload[:end_date]).to eq(today.iso8601)
      expect(payload[:days].length).to eq(365)
      expect(payload[:days].first[:date]).to eq((today - 364.days).iso8601)
      expect(payload[:days].last[:date]).to eq(today.iso8601)
    end

    it "includes per-day breakdowns and totals" do
      # Use dates a few days back rather than `today` itself. The service caps
      # end_date with `Date.current` (Time.zone-aware) and builds its window
      # with `.beginning_of_day` / `.end_of_day`, while grouping by UTC
      # `DATE(...)`. Activity timestamped near the day boundary can otherwise
      # land outside the window in TZ-aware CI environments (e.g. Zonebie).
      article_day = today - 5.days
      comment_day = today - 4.days
      reaction_day = today - 3.days

      article = create(:article, user: user, published: true)
      backdate_article(article, noon_utc_for(article_day))
      comment = create(:comment, user: user)
      comment.update_columns(created_at: noon_utc_for(comment_day))
      r1 = create(:reaction, user: user, category: "like")
      r2 = create(:reaction, user: user, category: "unicorn")
      r1.update_columns(created_at: noon_utc_for(reaction_day))
      r2.update_columns(created_at: noon_utc_for(reaction_day))

      payload = service.call

      bucket = ->(date) { payload[:days].detect { |d| d[:date] == date.iso8601 } }
      expect(bucket.call(article_day)).to include(articles: 1, total: 1)
      expect(bucket.call(comment_day)).to include(comments: 1, total: 1)
      expect(bucket.call(reaction_day)).to include(reactions: 2, total: 2)

      expect(payload[:totals]).to eq(articles: 1, comments: 1, reactions: 2, total: 4)
      expect(payload[:max]).to eq(2)
    end

    it "excludes unpublished articles, deleted comments, and non-public reactions" do
      create(:article, user: user, published: false, published_at: nil)
      deleted = create(:comment, user: user)
      deleted.update_columns(deleted: true)

      # Insert the readinglist reaction via raw SQL so we don't trip any
      # Reaction/Article factory callbacks that have caused incidental
      # `like`-category reactions to be attributed to the test user in CI.
      article_for_reaction = create(:article, user: create(:user), published: true)
      Reaction.insert_all!([{
        user_id: user.id,
        reactable_type: "Article",
        reactable_id: article_for_reaction.id,
        category: "readinglist",
        status: "valid",
        created_at: Time.current,
        updated_at: Time.current,
      }])
      # Drop anything else attributed to our user so the assertion only
      # exercises the public_category scope filtering we care about.
      Reaction.where(user_id: user.id).where.not(category: "readinglist").delete_all

      payload = service.call

      expect(payload[:totals]).to eq(articles: 0, comments: 0, reactions: 0, total: 0)
      expect(payload[:max]).to eq(0)
    end

    it "excludes activity outside the window" do
      article = create(:article, user: user, published: true)
      backdate_article(article, noon_utc_for(today - 400.days))
      future_comment = create(:comment, user: user)
      future_comment.update_columns(created_at: noon_utc_for(today + 1.day))

      payload = service.call

      expect(payload[:totals][:total]).to eq(0)
    end

    it "ignores other users' activity" do
      other = create(:user)
      article = create(:article, user: other, published: true)
      backdate_article(article, noon_utc_for(today - 1.day))

      payload = service.call

      expect(payload[:totals][:total]).to eq(0)
    end

    it "clamps end_date to today so future dates can't be queried" do
      future = described_class.new(user, end_date: Date.current + 30.days)

      payload = future.call

      expect(Date.parse(payload[:end_date])).to eq(Date.current)
    end

    it "honors a custom historical end_date" do
      historical_end = Date.new(2024, 12, 31)
      in_window = create(:article, user: user, published: true)
      backdate_article(in_window, Time.zone.local(2024, 6, 15))
      out_of_window = create(:article, user: user, published: true)
      backdate_article(out_of_window, Time.zone.local(2025, 1, 1))

      payload = described_class.new(user, end_date: historical_end).call

      expect(payload[:end_date]).to eq("2024-12-31")
      expect(payload[:start_date]).to eq("2024-01-02")
      expect(payload[:totals][:articles]).to eq(1)
    end

    it "uses a longer cache TTL for past windows than rolling windows" do
      expect(described_class::CACHE_TTL_HISTORICAL).to be > described_class::CACHE_TTL_ROLLING

      cache = ActiveSupport::Cache::MemoryStore.new
      allow(Rails).to receive(:cache).and_return(cache)
      allow(cache).to receive(:fetch).and_call_original

      described_class.new(user, end_date: Date.current - 2.years).call

      expect(cache).to have_received(:fetch).with(anything, expires_in: described_class::CACHE_TTL_HISTORICAL)
    end

    it "varies the cache key by end_date so years are cached independently" do
      cache = ActiveSupport::Cache::MemoryStore.new
      allow(Rails).to receive(:cache).and_return(cache)

      described_class.new(user, end_date: Date.new(2025, 12, 31)).call
      described_class.new(user, end_date: Date.new(2024, 12, 31)).call

      keys = cache.instance_variable_get(:@data).keys
      expect(keys.count { |k| k.include?("user-activity-heatmap-v1") }).to eq(2)
    end
  end
end
