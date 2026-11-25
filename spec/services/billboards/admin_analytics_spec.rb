require "rails_helper"

RSpec.describe Billboards::AdminAnalytics do
  include ActiveSupport::Testing::TimeHelpers

  let(:now) { Time.zone.local(2026, 11, 25, 14, 0, 0) }

  before { travel_to(now) }

  describe ".overview_summary" do
    it "aggregates live, inactive, expired, capped, expiring-soon, and campaign metrics", :aggregate_failures do
      active_campaign = BillboardCampaign.create!(name: "Active Campaign", expires_at: now + 5.days)
      expired_campaign = BillboardCampaign.create!(name: "Expired Campaign", expires_at: now - 1.hour)

      live_bb = create(:billboard, approved: true, published: true, priority: true,
                                   billboard_campaign: active_campaign, expires_at: now + 12.hours)
      live_bb.update_columns(impressions_count: 1_000, clicks_count: 25, seconds_visible: 5_000)

      draft_bb = create(:billboard, approved: false, published: false)
      draft_bb.update_columns(impressions_count: 200, clicks_count: 2)

      expired_campaign_bb = create(:billboard, approved: true, published: true)
      expired_campaign_bb.update_columns(billboard_campaign_id: expired_campaign.id, impressions_count: 300)

      capped_bb = create(:billboard, approved: false, published: true)
      capped_bb.update_columns(max_impressions_count: 500, impressions_count: 500, clicks_count: 10)

      summary = described_class.overview_summary(now: now)

      expect(summary.timed_out).to be(false)
      expect(summary.total_count).to eq(4)
      expect(summary.live_count).to eq(1)
      expect(summary.prioritized_live_count).to eq(1)
      expect(summary.expiring_soon_count).to eq(1)
      expect(summary.draft_or_paused_count).to eq(1)
      expect(summary.expired_count).to eq(1)
      expect(summary.capped_count).to eq(1)
      expect(summary.live_impressions).to eq(1_000)
      expect(summary.live_clicks).to eq(25)
      expect(summary.total_impressions).to eq(2_000)
      expect(summary.total_clicks).to eq(37)
      expect(summary.active_campaigns_count).to eq(1)
      expect(summary.total_campaigns_count).to eq(2)
    end

    it "caches the overview summary and avoids caching timed-out responses", :aggregate_failures do
      memory_store = ActiveSupport::Cache::MemoryStore.new
      allow(Rails).to receive(:cache).and_return(memory_store)
      allow(Rails.logger).to receive(:warn)

      allow(ReadOnlyDatabaseService).to receive(:with_connection).and_raise(ActiveRecord::QueryCanceled, "timeout")
      timed_out = described_class.overview_summary(now: now)
      expect(timed_out.timed_out).to be(true)
      expect(memory_store.read(described_class::OVERVIEW_CACHE_KEY)).to be_nil

      allow(ReadOnlyDatabaseService).to receive(:with_connection).and_call_original
      create(:billboard, approved: true, published: true)

      first = described_class.overview_summary(now: now)
      expect(first.timed_out).to be(false)
      expect(first.live_count).to eq(1)

      second = described_class.overview_summary(now: now)
      expect(second.live_count).to eq(1)
      expect(ReadOnlyDatabaseService).to have_received(:with_connection).twice
    end
  end

  describe ".campaigns_overview_summary and .campaign_rollups" do
    it "aggregates campaign KPIs and per-campaign rollups in a single batched query", :aggregate_failures do
      active_paced = BillboardCampaign.create!(
        name: "Paced Launch",
        ideal_daily_impressions: 5_000,
        delivery_throttle_rate: 0.65,
        max_impressions_count: 50_000,
      )
      ended = BillboardCampaign.create!(name: "Finished", expires_at: now - 1.day)

      bb_a = create(:billboard, approved: true, published: true, priority: true, weight: 2.5,
                                billboard_campaign: active_paced)
      bb_a.update_columns(impressions_count: 600, clicks_count: 18, seconds_visible: 3_000)
      bb_b = create(:billboard, approved: false, published: true, weight: 0.5, billboard_campaign: active_paced)
      bb_b.update_columns(impressions_count: 400, clicks_count: 12, seconds_visible: 1_000)

      overview = described_class.campaigns_overview_summary(now: now)
      expect(overview.total_campaigns).to eq(2)
      expect(overview.active_campaigns).to eq(1)
      expect(overview.paced_campaigns).to eq(1)
      expect(overview.throttled_campaigns).to eq(1)
      expect(overview.ended_campaigns).to eq(1)
      expect(overview.total_live_billboards).to eq(1)
      expect(overview.total_impressions).to eq(1_000)
      expect(overview.total_clicks).to eq(30)

      rollups = described_class.campaign_rollups([active_paced.id, ended.id], now: now)
      rollup = rollups[active_paced.id]
      expect(rollup).to have_attributes(
        billboards_count: 2,
        live_billboards_count: 1,
        prioritized_count: 1,
        impressions_count: 1_000,
        clicks_count: 30,
        seconds_visible: 4_000,
        min_weight: 0.5,
        max_weight: 2.5,
      )
      expect(rollup.ctr).to be_within(0.0001).of(0.03)
      expect(rollup.avg_seconds_visible).to be_within(0.01).of(4.0)
      expect(rollups[ended.id]).to be_nil
    end
  end

  describe ".campaign_daily_series" do
    let(:billboard) { create(:billboard, approved: true, published: true) }

    it "returns 14 daily buckets with zero-filled gaps and trailing 24h counts", :aggregate_failures do
      create(:billboard_event, billboard: billboard, category: "impression", counts_for: 100,
                               created_at: now - 3.days)
      create(:billboard_event, billboard: billboard, category: "click", counts_for: 4,
                               created_at: now - 3.days)
      create(:billboard_event, billboard: billboard, category: "impression", counts_for: 250,
                               created_at: now - 2.hours)
      create(:billboard_event, billboard: billboard, category: "click", counts_for: 10,
                               created_at: now - 1.hour)
      create(:billboard_event, billboard: billboard, category: "conversion", counts_for: 2,
                               created_at: now - 1.hour)

      series = described_class.campaign_daily_series([billboard.id], days: 14, now: now)

      expect(series.timed_out).to be(false)
      expect(series.points.size).to eq(14)
      expect(series.total_impressions).to eq(350)
      expect(series.total_clicks).to eq(14)
      expect(series.total_conversions).to eq(2)
      expect(series.past_24h_impressions).to eq(250)
      expect(series.past_24h_clicks).to eq(10)
      expect(series.max_daily_impressions).to eq(250)
    end

    it "degrades gracefully when the read-replica query times out", :aggregate_failures do
      allow(ReadOnlyDatabaseService).to receive(:with_connection).and_raise(ActiveRecord::QueryCanceled, "timeout")
      allow(Rails.logger).to receive(:warn)

      series = described_class.campaign_daily_series([billboard.id], days: 7, now: now)

      expect(series.timed_out).to be(true)
      expect(series.points.size).to eq(7)
      expect(series.total_impressions).to eq(0)
      expect(Rails.logger).to have_received(:warn).with(/timed out/)
    end

    it "uses UTC midnight for the first bucket regardless of active Rails time zone", :aggregate_failures do
      first_utc_day = now.utc.to_date - 6
      early_utc_event_time = Time.utc(first_utc_day.year, first_utc_day.month, first_utc_day.day, 1, 0, 0)
      create(:billboard_event, billboard: billboard, category: "impression", counts_for: 42,
                               created_at: early_utc_event_time)

      series = Time.use_zone("America/Los_Angeles") do
        described_class.campaign_daily_series([billboard.id], days: 7, now: now)
      end

      expect(series.points.first.date).to eq(first_utc_day)
      expect(series.points.first.impressions).to eq(42)
      expect(series.total_impressions).to eq(42)
    end
  end

  describe ".placement_breakdown" do
    it "groups billboards by placement area and sorts by impressions descending", :aggregate_failures do
      bb_sidebar = create(:billboard, placement_area: "post_sidebar", approved: true, published: true)
      bb_sidebar.update_columns(impressions_count: 800, clicks_count: 16)
      bb_feed = create(:billboard, placement_area: "feed_first", approved: false, published: true)
      bb_feed.update_columns(impressions_count: 200, clicks_count: 10)

      rows = described_class.placement_breakdown([bb_sidebar, bb_feed], now: now)

      expect(rows.map(&:placement_area)).to eq(%w[post_sidebar feed_first])
      expect(rows.first.impression_share).to be_within(0.001).of(0.8)
      expect(rows.first.live_count).to eq(1)
      expect(rows.second.live_count).to eq(0)
    end
  end
end
