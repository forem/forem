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
      two_days_ago = today.beginning_of_day - 2.days
      yesterday = today.beginning_of_day - 1.day
      now = Time.current

      article = create(:article, user: user, published: true)
      backdate_article(article, two_days_ago)
      comment = create(:comment, user: user)
      comment.update_columns(created_at: yesterday)
      r1 = create(:reaction, user: user, category: "like")
      r2 = create(:reaction, user: user, category: "unicorn")
      r1.update_columns(created_at: now)
      r2.update_columns(created_at: now)

      payload = service.call

      bucket = ->(date) { payload[:days].detect { |d| d[:date] == date.iso8601 } }
      expect(bucket.call(today - 2.days)).to include(articles: 1, total: 1)
      expect(bucket.call(today - 1.day)).to include(comments: 1, total: 1)
      expect(bucket.call(today)).to include(reactions: 2, total: 2)

      expect(payload[:totals]).to eq(articles: 1, comments: 1, reactions: 2, total: 4)
      expect(payload[:max]).to eq(2)
    end

    it "excludes unpublished articles, deleted comments, and non-public reactions" do
      # Start from a known-empty state for the test user. Other factories
      # (article/comment) can trigger side-effects that touch the reactions
      # table, which has caused flaky leakage in CI runs where this spec
      # asserts a zero reactions total.
      Reaction.where(user_id: user.id).delete_all

      create(:article, user: user, published: false, published_at: nil)
      deleted = create(:comment, user: user)
      deleted.update_columns(deleted: true)
      # readinglist is explicitly excluded from the `public_category` scope
      # the heatmap uses; ensures we only count visible-to-public reactions.
      create(:reading_reaction, user: user)

      # Belt and braces: drop any non-readinglist reactions an upstream
      # factory may have created so this test only exercises the scope
      # filtering we care about.
      Reaction.where(user_id: user.id).where.not(category: "readinglist").delete_all

      payload = service.call

      expect(payload[:totals]).to eq(articles: 0, comments: 0, reactions: 0, total: 0)
      expect(payload[:max]).to eq(0)
    end

    it "excludes activity outside the window" do
      article = create(:article, user: user, published: true)
      backdate_article(article, today.beginning_of_day - 400.days)
      future_comment = create(:comment, user: user)
      future_comment.update_columns(created_at: today.beginning_of_day + 1.day)

      payload = service.call

      expect(payload[:totals][:total]).to eq(0)
    end

    it "ignores other users' activity" do
      other = create(:user)
      article = create(:article, user: other, published: true)
      backdate_article(article, today.beginning_of_day - 1.day)

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
