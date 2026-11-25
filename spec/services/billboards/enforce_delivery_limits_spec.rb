require "rails_helper"

RSpec.describe Billboards::EnforceDeliveryLimits do
  let(:now) { Time.current.change(usec: 0) }

  before do
    allow(Rails).to receive(:cache).and_return(ActiveSupport::Cache::MemoryStore.new)
    Rails.cache.clear
    MemoryFirstCache.clear
  end

  describe ".sweep!" do
    it "takes down expired and self-capped approved billboards while leaving active ones up", :aggregate_failures do
      expired_bb = create(:billboard, approved: true, published: true, placement_area: "sidebar_left")
      expired_bb.update_column(:expires_at, now - 1.minute)

      impression_capped_bb = create(:billboard, approved: true, published: true, placement_area: "post_sidebar")
      impression_capped_bb.update_columns(max_impressions_count: 100, impressions_count: 100)

      click_capped_bb = create(:billboard, approved: true, published: false, placement_area: "feed_first")
      click_capped_bb.update_columns(max_clicks_count: 10, clicks_count: 12)

      active_bb = create(:billboard, approved: true, published: true, expires_at: now + 1.day,
                                     max_impressions_count: 100, impressions_count: 99)
      allow(EdgeCache::PurgeByKey).to receive(:call)

      taken_down = described_class.sweep!(now: now)

      expect(taken_down).to contain_exactly(expired_bb.id, impression_capped_bb.id, click_capped_bb.id)
      expect(expired_bb.reload.approved).to be(false)
      expect(impression_capped_bb.reload.approved).to be(false)
      expect(click_capped_bb.reload.approved).to be(false)
      expect(active_bb.reload.approved).to be(true)

      expect(EdgeCache::PurgeByKey).to have_received(:call).with(expired_bb.record_key).once
      expect(EdgeCache::PurgeByKey).to have_received(:call).with(impression_capped_bb.record_key).once
      expect(EdgeCache::PurgeByKey).not_to have_received(:call).with(click_capped_bb.record_key)
      expect(EdgeCache::PurgeByKey).not_to have_received(:call).with("main_app_home_page", fallback_paths: "/")
    end

    it "takes down all approved billboards in an expired campaign and purges the home page once", :aggregate_failures do
      campaign = BillboardCampaign.create!(name: "Expired Promo", expires_at: now - 1.minute)
      home_bb_a = create(:billboard, approved: true, published: true, placement_area: "feed_first")
      home_bb_b = create(:billboard, approved: true, published: true, placement_area: "sidebar_right")
      unapproved_bb = create(:billboard, approved: false, published: true, placement_area: "post_sidebar")
      [home_bb_a, home_bb_b, unapproved_bb].each { |bb| bb.update_column(:billboard_campaign_id, campaign.id) }
      allow(EdgeCache::PurgeByKey).to receive(:call)

      taken_down = described_class.sweep!(now: now)

      expect(taken_down).to contain_exactly(home_bb_a.id, home_bb_b.id)
      expect(home_bb_a.reload.approved).to be(false)
      expect(home_bb_b.reload.approved).to be(false)
      expect(EdgeCache::PurgeByKey).to have_received(:call).with(home_bb_a.record_key).once
      expect(EdgeCache::PurgeByKey).to have_received(:call).with(home_bb_b.record_key).once
      expect(EdgeCache::PurgeByKey).not_to have_received(:call).with(unapproved_bb.record_key)
      expect(EdgeCache::PurgeByKey).to have_received(:call).with("main_app_home_page", fallback_paths: "/").once
    end

    it "sums both approved and unapproved member billboards when checking campaign caps", :aggregate_failures do
      campaign = BillboardCampaign.create!(name: "Combined Cap", max_impressions_count: 150)
      live_a = create(:billboard, approved: true, published: true)
      live_b = create(:billboard, approved: true, published: true)
      paused_member = create(:billboard, approved: false, published: false)
      live_a.update_columns(billboard_campaign_id: campaign.id, impressions_count: 40)
      live_b.update_columns(billboard_campaign_id: campaign.id, impressions_count: 30)
      paused_member.update_columns(billboard_campaign_id: campaign.id, impressions_count: 80)

      under_cap_campaign = BillboardCampaign.create!(name: "Under Cap", max_clicks_count: 20)
      under_cap_bb = create(:billboard, approved: true, published: true)
      under_cap_bb.update_columns(billboard_campaign_id: under_cap_campaign.id, clicks_count: 19)

      taken_down = described_class.sweep!(now: now)

      expect(taken_down).to contain_exactly(live_a.id, live_b.id)
      expect(live_a.reload.approved).to be(false)
      expect(live_b.reload.approved).to be(false)
      expect(under_cap_bb.reload.approved).to be(true)
    end

    it "unpublishes liquid embed references and busts feed targets cache once across taken-down billboards",
       :aggregate_failures do
      campaign = BillboardCampaign.create!(name: "Embeds", expires_at: now - 5.minutes)
      bb_a = create(:billboard, approved: true, published: true)
      bb_b = create(:billboard, approved: true, published: true)
      [bb_a, bb_b].each { |bb| bb.update_column(:billboard_campaign_id, campaign.id) }

      ref_a = LiquidEmbedReference.create!(record: bb_a, tag_name: "link", url: "/a", published: true)
      ref_b = LiquidEmbedReference.create!(record: bb_b, tag_name: "link", url: "/b", published: true)
      allow(LiquidEmbedReference).to receive(:bust_feed_targets_cache!)

      described_class.sweep!(now: now)

      expect(ref_a.reload.published).to be(false)
      expect(ref_b.reload.published).to be(false)
      expect(LiquidEmbedReference).to have_received(:bust_feed_targets_cache!).once
    end

    it "refreshes the throttled campaign cache when an expired paced campaign is swept", :aggregate_failures do
      expired_paced = BillboardCampaign.create!(
        name: "Expired Paced",
        ideal_daily_impressions: 5_000,
        delivery_throttle_rate: 0.25,
        expires_at: now - 1.minute,
      )
      active_paced = BillboardCampaign.create!(
        name: "Active Paced",
        ideal_daily_impressions: 5_000,
        delivery_throttle_rate: 0.5,
        expires_at: now + 1.day,
      )
      bb = create(:billboard, approved: true, published: true)
      bb.update_column(:billboard_campaign_id, expired_paced.id)
      Billboards::CampaignPacing.write_throttled_campaign_rates(expired_paced.id => 0.25, active_paced.id => 0.5)

      described_class.sweep!(now: now)

      expect(bb.reload.approved).to be(false)
      expect(Billboards::CampaignPacing.throttled_campaign_rates).to eq(active_paced.id => 0.5)
    end

    it "is idempotent on subsequent runs", :aggregate_failures do
      bb = create(:billboard, approved: true, published: true)
      bb.update_column(:expires_at, now - 1.minute)
      allow(EdgeCache::PurgeByKey).to receive(:call)

      expect(described_class.sweep!(now: now)).to eq([bb.id])
      expect(described_class.sweep!(now: now)).to eq([])
      expect(EdgeCache::PurgeByKey).to have_received(:call).with(bb.record_key).once
    end
  end

  describe ".enforce_for_billboard!" do
    it "takes down all approved siblings when the campaign hits its cap", :aggregate_failures do
      campaign = BillboardCampaign.create!(name: "Shared Cap", max_impressions_count: 100)
      triggering = create(:billboard, approved: true, published: true)
      sibling = create(:billboard, approved: true, published: true)
      triggering.update_columns(billboard_campaign_id: campaign.id, impressions_count: 60)
      sibling.update_columns(billboard_campaign_id: campaign.id, impressions_count: 40)

      taken_down = described_class.enforce_for_billboard!(triggering, now: now)

      expect(taken_down).to contain_exactly(triggering.id, sibling.id)
      expect(triggering.approved).to be(false)
      expect(triggering.reload.approved).to be(false)
      expect(sibling.reload.approved).to be(false)
    end

    it "takes down approved siblings even when the triggering billboard is already unapproved", :aggregate_failures do
      campaign = BillboardCampaign.create!(name: "Late Event Cap", max_clicks_count: 10)
      triggering = create(:billboard, approved: false, published: false)
      sibling = create(:billboard, approved: true, published: true)
      triggering.update_columns(billboard_campaign_id: campaign.id, clicks_count: 6)
      sibling.update_columns(billboard_campaign_id: campaign.id, clicks_count: 4)

      taken_down = described_class.enforce_for_billboard!(triggering, now: now)

      expect(taken_down).to eq([sibling.id])
      expect(sibling.reload.approved).to be(false)
    end

    it "takes down only the triggering billboard when only its individual cap is reached", :aggregate_failures do
      campaign = BillboardCampaign.create!(name: "Uncapped Campaign")
      capped = create(:billboard, approved: true, published: true, max_impressions_count: 50)
      sibling = create(:billboard, approved: true, published: true)
      capped.update_columns(billboard_campaign_id: campaign.id, impressions_count: 50)
      sibling.update_columns(billboard_campaign_id: campaign.id, impressions_count: 10)

      taken_down = described_class.enforce_for_billboard!(capped, now: now)

      expect(taken_down).to eq([capped.id])
      expect(capped.reload.approved).to be(false)
      expect(sibling.reload.approved).to be(true)
    end
  end

  describe ".enforce_campaign!" do
    it "logs and does not raise if throttle cache refresh fails after taking down billboards", :aggregate_failures do
      campaign = BillboardCampaign.create!(
        name: "Redis Blip",
        ideal_daily_impressions: 5_000,
        delivery_throttle_rate: 0.2,
        expires_at: now - 1.minute,
      )
      bb = create(:billboard, approved: true, published: true)
      bb.update_column(:billboard_campaign_id, campaign.id)

      allow(Billboards::CampaignPacing).to receive(:refresh_throttled_campaign_rates_cache!)
        .and_raise(StandardError, "redis unavailable")
      allow(Rails.logger).to receive(:error)

      expect { described_class.enforce_campaign!(campaign, now: now) }.not_to raise_error
      expect(bb.reload.approved).to be(false)
      expect(Rails.logger).to have_received(:error).with(/throttle cache refresh failed: redis unavailable/)
    end
  end
end
