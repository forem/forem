require "rails_helper"

RSpec.describe Billboards::TitrateCampaignImpressionsWorker, type: :worker do
  include ActiveSupport::Testing::TimeHelpers

  let(:worker) { described_class.new }
  let(:now) { Time.utc(2026, 11, 20, 14, 0, 0) }

  before do
    Sidekiq::Worker.clear_all
    allow(Rails).to receive(:cache).and_return(ActiveSupport::Cache::MemoryStore.new)
    Rails.cache.clear
    MemoryFirstCache.clear
    allow(Billboards::TrafficProfile).to receive(:multiplier_for).and_return(1.0)
  end

  describe "#perform" do
    it "clears the throttle cache and exits cleanly when no active paced campaigns exist" do
      Billboards::CampaignPacing.write_throttled_campaign_rates(999 => 0.2)
      BillboardCampaign.create!(name: "Unpaced", ideal_daily_impressions: 0)
      BillboardCampaign.create!(name: "Expired", ideal_daily_impressions: 5_000, expires_at: 1.hour.ago)

      travel_to(now) { worker.perform }

      expect(Billboards::CampaignPacing.throttled_campaign_rates).to eq({})
    end

    it "titrates multiple campaigns across weight, priority, and throttle levers in one pass", :aggregate_failures do
      # 1. Under-delivering campaign (target 100 per 10m, got 10)
      under_campaign = BillboardCampaign.create!(name: "Under", ideal_daily_impressions: 14_400)
      under_bb = create(:billboard, billboard_campaign: under_campaign, approved: true, published: true,
                                    priority: false, weight: 2.0)
      create(:billboard_event, billboard: under_bb, category: "impression", counts_for: 10, created_at: now - 5.minutes)
      # Older impressions (> 10 minutes ago) and clicks should NOT count
      create(:billboard_event, billboard: under_bb, category: "impression", counts_for: 500,
                               created_at: now - 15.minutes)
      create(:billboard_event, billboard: under_bb, category: "click", counts_for: 500, created_at: now - 3.minutes)

      # 2. On-target campaign (target 100 per 10m, got 98 -> within deadband)
      steady_campaign = BillboardCampaign.create!(name: "Steady", ideal_daily_impressions: 14_400)
      steady_bb = create(:billboard, billboard_campaign: steady_campaign, approved: true, published: true,
                                     priority: true, weight: 5.0)
      create(:billboard_event, billboard: steady_bb, category: "impression", counts_for: 98,
                               created_at: now - 4.minutes)

      # 3. Over-delivering campaign with priority & high weight -> dials down weight
      over_weight_campaign = BillboardCampaign.create!(name: "Over Weight", ideal_daily_impressions: 14_400)
      over_weight_bb = create(:billboard, billboard_campaign: over_weight_campaign, approved: true, published: true,
                                          priority: true, weight: 40.0)
      create(:billboard_event, billboard: over_weight_bb, category: "impression", counts_for: 400,
                               created_at: now - 2.minutes)

      # 4. Over-delivering campaign already off priority & low weight -> engages delivery_throttle_rate
      over_organic_campaign = BillboardCampaign.create!(name: "Over Organic", ideal_daily_impressions: 1_440)
      over_organic_bb = create(:billboard, billboard_campaign: over_organic_campaign, approved: true, published: true,
                                           priority: false, weight: 0.5)
      create(:billboard_event, billboard: over_organic_bb, category: "impression", counts_for: 60,
                               created_at: now - 2.minutes)

      travel_to(now) do
        worker.perform

        under_bb.reload
        expect(under_bb.priority).to be(true)
        expect(under_bb.weight).to be > 2.0
        expect(under_campaign.reload.delivery_throttle_rate).to eq(1.0)

        steady_bb.reload
        expect(steady_bb.priority).to be(true)
        expect(steady_bb.weight).to eq(5.0)

        over_weight_bb.reload
        expect(over_weight_bb.weight).to be < 40.0
        expect(over_weight_campaign.reload.delivery_throttle_rate).to eq(1.0)

        over_organic_bb.reload
        over_organic_campaign.reload
        expect(over_organic_bb.priority).to be(false)
        expect(over_organic_bb.weight).to eq(Billboards::CampaignPacing::MIN_WEIGHT)
        expect(over_organic_campaign.delivery_throttle_rate).to be < 1.0

        expect(Billboards::CampaignPacing.throttled_campaign_rates).to eq(
          over_organic_campaign.id => over_organic_campaign.delivery_throttle_rate,
        )
      end
    end

    it "counts impressions from recently unpublished campaign billboards toward the 10-minute total" do
      campaign = BillboardCampaign.create!(name: "Multi-creative", ideal_daily_impressions: 14_400)
      live_bb = create(:billboard, billboard_campaign: campaign, approved: true, published: true,
                                   priority: true, weight: 5.0)
      paused_bb = create(:billboard, billboard_campaign: campaign, approved: true, published: false,
                                     priority: true, weight: 5.0)

      create(:billboard_event, billboard: live_bb, category: "impression", counts_for: 50, created_at: now - 3.minutes)
      create(:billboard_event, billboard: paused_bb, category: "impression", counts_for: 50,
                               created_at: now - 3.minutes)

      travel_to(now) { worker.perform }

      # Total is 100 vs 100 expected -> within deadband, neither billboard changes
      expect(live_bb.reload.weight).to eq(5.0)
      expect(paused_bb.reload.weight).to eq(5.0)
    end

    it "uses the traffic profile multiplier for the current time" do
      allow(Billboards::TrafficProfile).to receive(:multiplier_for).with(now).and_return(2.0)

      campaign = BillboardCampaign.create!(name: "Peak Aware", ideal_daily_impressions: 14_400)
      bb = create(:billboard, billboard_campaign: campaign, approved: true, published: true,
                              priority: true, weight: 5.0)
      # 100 actual would be on-target at 1.0x, but expected is 200 at 2.0x -> ramps up!
      create(:billboard_event, billboard: bb, category: "impression", counts_for: 100, created_at: now - 3.minutes)

      travel_to(now) { worker.perform }

      expect(bb.reload.weight).to be > 5.0
    end

    it "re-raises ActiveRecord::QueryCanceled so Sidekiq retries on timeout" do
      campaign = BillboardCampaign.create!(name: "Timeout", ideal_daily_impressions: 14_400)
      create(:billboard, billboard_campaign: campaign, approved: true, published: true)
      allow(ReadOnlyDatabaseService).to receive(:with_connection)
        .and_raise(ActiveRecord::QueryCanceled.new("statement timeout"))

      travel_to(now) do
        expect { worker.perform }.to raise_error(ActiveRecord::QueryCanceled)
      end
    end

    it "does not overwrite or re-throttle a campaign disabled concurrently after initial load" do
      campaign = BillboardCampaign.create!(name: "Disabled Mid-Run", ideal_daily_impressions: 1_440)
      bb = create(:billboard, billboard_campaign: campaign, approved: true, published: true,
                              priority: false, weight: 0.5)
      create(:billboard_event, billboard: bb, category: "impression", counts_for: 60, created_at: now - 2.minutes)

      # Simulate pacing being disabled after the worker loads active campaigns and while it reads events
      allow(ReadOnlyDatabaseService).to receive(:with_connection).and_wrap_original do |original, &block|
        result = original.call(&block)
        campaign.update!(ideal_daily_impressions: 0)
        result
      end

      travel_to(now) do
        worker.perform

        expect(campaign.reload.delivery_throttle_rate).to eq(1.0)
        expect(bb.reload.weight).to eq(0.5)
        expect(Billboards::CampaignPacing.throttled_campaign_rates).to eq({})
      end
    end

    it "rolls back billboard updates atomically if campaign updates fail" do
      campaign = BillboardCampaign.create!(name: "Atomic", ideal_daily_impressions: 1_440)
      bb = create(:billboard, billboard_campaign: campaign, approved: true, published: true,
                              priority: false, weight: 0.5)
      create(:billboard_event, billboard: bb, category: "impression", counts_for: 60, created_at: now - 2.minutes)

      allow(worker).to receive(:batch_update_campaigns).and_raise(ActiveRecord::StatementInvalid, "db blip")

      travel_to(now) do
        expect { worker.perform }.to raise_error(ActiveRecord::StatementInvalid)
        expect(bb.reload.weight).to eq(0.5)
        expect(campaign.reload.delivery_throttle_rate).to eq(1.0)
      end
    end

    it "logs cache publish failures after DB commit instead of raising for a duplicate retry" do
      campaign = BillboardCampaign.create!(name: "Cache Blip", ideal_daily_impressions: 14_400)
      bb = create(:billboard, billboard_campaign: campaign, approved: true, published: true,
                              priority: false, weight: 2.0)

      allow(Billboards::CampaignPacing).to receive(:refresh_throttled_campaign_rates_cache!)
        .and_raise(Redis::CannotConnectError, "redis down")
      allow(Rails.logger).to receive(:error)

      travel_to(now) do
        expect { worker.perform }.not_to raise_error
        expect(bb.reload.weight).to be > 2.0
        expect(Rails.logger).to have_received(:error).with(/cache publish failed: redis down/)
      end
    end
  end
end
