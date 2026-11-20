require "rails_helper"

RSpec.describe Billboards::CampaignPacing do
  let(:billboard_struct) { Struct.new(:id, :weight, :priority, keyword_init: true) }

  before do
    allow(Rails).to receive(:cache).and_return(ActiveSupport::Cache::MemoryStore.new)
    Rails.cache.clear
    MemoryFirstCache.clear
  end

  describe ".calculate_adjustments" do
    it "returns no updates when actual impressions are within the deadband" do
      # ideal = 14_400/day => 100 per 10m; ratio = (100 + 3) / (100 + 3) = 1.0
      bb = billboard_struct.new(id: 1, weight: 5.0, priority: true)

      result = described_class.calculate_adjustments(
        ideal_daily_impressions: 14_400,
        actual_impressions: 100,
        traffic_multiplier: 1.0,
        current_throttle_rate: 1.0,
        billboards: [bb],
      )

      expect(result.throttle_rate).to eq(1.0)
      expect(result.billboard_updates).to be_empty
    end

    it "ramps up priority and weight proportionally when under-delivering" do
      bb = billboard_struct.new(id: 1, weight: 2.0, priority: false)

      result = described_class.calculate_adjustments(
        ideal_daily_impressions: 14_400, # 100 expected
        actual_impressions: 25,
        traffic_multiplier: 1.0,
        current_throttle_rate: 1.0,
        billboards: [bb],
      )

      expect(result.throttle_rate).to eq(1.0)
      expect(result.billboard_updates.size).to eq(1)
      update = result.billboard_updates.first
      expect(update.priority).to be(true)
      expect(update.weight).to be > 2.0
      expect(update.weight).to be <= 8.0 # bounded by MAX_UP_FACTOR (4.0)
    end

    it "applies Laplace smoothing so tiny campaigns do not swing wildly on 0 or 2 impressions" do
      # ideal = 144/day => expected = 1.0 per 10m
      bb = billboard_struct.new(id: 1, weight: 1.0, priority: true)

      zero_result = described_class.calculate_adjustments(
        ideal_daily_impressions: 144,
        actual_impressions: 0,
        traffic_multiplier: 1.0,
        current_throttle_rate: 1.0,
        billboards: [bb],
      )
      expect(zero_result.billboard_updates.first.weight).to be_between(1.05, 1.3)

      two_result = described_class.calculate_adjustments(
        ideal_daily_impressions: 144,
        actual_impressions: 2,
        traffic_multiplier: 1.0,
        current_throttle_rate: 1.0,
        billboards: [bb],
      )
      expect(two_result.billboard_updates.first.weight).to be_between(0.75, 0.95)
    end

    it "scales expected impressions by the traffic_multiplier" do
      bb = billboard_struct.new(id: 1, weight: 5.0, priority: true)

      # 100 actual is on-target at 1.0x, but under-delivering at 2.0x peak traffic (expected 200)
      peak_result = described_class.calculate_adjustments(
        ideal_daily_impressions: 14_400,
        actual_impressions: 100,
        traffic_multiplier: 2.0,
        current_throttle_rate: 1.0,
        billboards: [bb],
      )
      expect(peak_result.billboard_updates.first.weight).to be > 5.0

      # 100 actual is over-delivering at 0.5x off-peak traffic (expected 50)
      quiet_result = described_class.calculate_adjustments(
        ideal_daily_impressions: 14_400,
        actual_impressions: 100,
        traffic_multiplier: 0.5,
        current_throttle_rate: 1.0,
        billboards: [bb],
      )
      expect(quiet_result.billboard_updates.first.weight).to be < 5.0
    end

    it "caps weight at MAX_WEIGHT" do
      bb = billboard_struct.new(id: 1, weight: 8_000.0, priority: true)

      result = described_class.calculate_adjustments(
        ideal_daily_impressions: 14_400,
        actual_impressions: 0,
        traffic_multiplier: 1.0,
        current_throttle_rate: 1.0,
        billboards: [bb],
      )

      expect(result.billboard_updates.first.weight).to eq(described_class::MAX_WEIGHT)
    end

    it "preserves explicit 0.0 weight on muted billboards when other creatives are active" do
      active = billboard_struct.new(id: 1, weight: 2.0, priority: false)
      muted = billboard_struct.new(id: 2, weight: 0.0, priority: false)

      result = described_class.calculate_adjustments(
        ideal_daily_impressions: 14_400,
        actual_impressions: 10,
        traffic_multiplier: 1.0,
        current_throttle_rate: 1.0,
        billboards: [active, muted],
      )

      expect(result.billboard_updates.map(&:id)).to eq([1])
    end

    it "recovers billboards when all live creatives have weight 0.0" do
      muted = billboard_struct.new(id: 1, weight: 0.0, priority: false)

      result = described_class.calculate_adjustments(
        ideal_daily_impressions: 14_400,
        actual_impressions: 10,
        traffic_multiplier: 1.0,
        current_throttle_rate: 1.0,
        billboards: [muted],
      )

      expect(result.billboard_updates.first.weight).to be > 0.0
      expect(result.billboard_updates.first.priority).to be(true)
    end

    it "dials down weight and turns off priority when over-delivering" do
      high_weight_bb = billboard_struct.new(id: 1, weight: 10.0, priority: true)
      low_weight_bb = billboard_struct.new(id: 2, weight: 1.2, priority: true)

      result = described_class.calculate_adjustments(
        ideal_daily_impressions: 14_400, # 100 expected
        actual_impressions: 300,
        traffic_multiplier: 1.0,
        current_throttle_rate: 1.0,
        billboards: [high_weight_bb, low_weight_bb],
      )

      expect(result.throttle_rate).to eq(1.0)
      high_update = result.billboard_updates.detect { |u| u.id == 1 }
      low_update = result.billboard_updates.detect { |u| u.id == 2 }

      expect(high_update.weight).to be < 10.0
      expect(high_update.priority).to be(true)

      expect(low_update.weight).to be <= described_class::PRIORITY_OFF_WEIGHT_THRESHOLD
      expect(low_update.priority).to be(false)
    end

    it "engages delivery_throttle_rate when over-delivering with priority off and low weight" do
      bb = billboard_struct.new(id: 1, weight: 0.5, priority: false)

      result = described_class.calculate_adjustments(
        ideal_daily_impressions: 1_440, # 10 expected
        actual_impressions: 60,
        traffic_multiplier: 1.0,
        current_throttle_rate: 1.0,
        billboards: [bb],
      )

      expect(result.throttle_rate).to be < 1.0
      expect(result.throttle_rate).to be >= described_class::MIN_DOWN_FACTOR
      expect(result.billboard_updates.first.weight).to eq(described_class::MIN_WEIGHT)
      expect(result.billboard_updates.first.priority).to be(false)
    end

    it "hard-pauses (throttle_rate 0.0) if over-delivery pushes rate below MIN_NONZERO_THROTTLE_RATE" do
      bb = billboard_struct.new(id: 1, weight: 0.01, priority: false)

      result = described_class.calculate_adjustments(
        ideal_daily_impressions: 1_440,
        actual_impressions: 100,
        traffic_multiplier: 1.0,
        current_throttle_rate: 0.02,
        billboards: [bb],
      )

      expect(result.throttle_rate).to eq(0.0)
    end

    it "reopens delivery_throttle_rate from 0.0 before boosting priority/weight" do
      bb = billboard_struct.new(id: 1, weight: 0.01, priority: false)

      result = described_class.calculate_adjustments(
        ideal_daily_impressions: 1_440,
        actual_impressions: 0,
        traffic_multiplier: 1.0,
        current_throttle_rate: 0.0,
        billboards: [bb],
      )

      expect(result.throttle_rate).to eq(described_class::MIN_OPEN_THROTTLE_RATE)
      expect(result.billboard_updates).to be_empty
    end

    it "reopens a paused low-target campaign instead of stalling in the deadband" do
      bb = billboard_struct.new(id: 1, weight: 0.01, priority: false)

      # ideal = 36 => expected = 0.25/10m; smoothed ratio (3.0 / 3.25 = 0.923) is inside the deadband,
      # but a hard-paused campaign (0.0) with positive expected delivery and 0 actual must still reopen.
      result = described_class.calculate_adjustments(
        ideal_daily_impressions: 36,
        actual_impressions: 0,
        traffic_multiplier: 1.0,
        current_throttle_rate: 0.0,
        billboards: [bb],
      )

      expect(result.throttle_rate).to eq(described_class::MIN_OPEN_THROTTLE_RATE)
      expect(result.billboard_updates).to be_empty
    end

    it "snaps delivery_throttle_rate cleanly to 1.0 when ramping up past threshold" do
      bb = billboard_struct.new(id: 1, weight: 0.01, priority: false)

      result = described_class.calculate_adjustments(
        ideal_daily_impressions: 14_400,
        actual_impressions: 50,
        traffic_multiplier: 1.0,
        current_throttle_rate: 0.85,
        billboards: [bb],
      )

      expect(result.throttle_rate).to eq(1.0)
      expect(result.billboard_updates).to be_empty
    end
  end

  describe "throttle cache helpers" do
    it "writes, reads, and applies probabilistic exclusion deterministically" do
      described_class.write_throttled_campaign_rates(10 => 0.0, 20 => 0.4, 30 => 1.0)

      expect(described_class.throttled_campaign_rates).to eq(10 => 0.0, 20 => 0.4)

      low_rng = Class.new { def rand = 0.2 }.new
      expect(described_class.excluded_campaign_ids(rng: low_rng)).to eq([10])

      high_rng = Class.new { def rand = 0.6 }.new
      expect(described_class.excluded_campaign_ids(rng: high_rng)).to contain_exactly(10, 20)
    end

    it "writes atomically without deleting from Redis first and does not write back on miss" do
      cache = Rails.cache
      allow(cache).to receive(:delete).and_call_original
      allow(cache).to receive(:write).and_call_original

      expect(described_class.throttled_campaign_rates).to eq({})
      expect(cache).not_to have_received(:write)

      described_class.write_throttled_campaign_rates(10 => 0.25)

      expect(cache).not_to have_received(:delete)
      expect(described_class.throttled_campaign_rates).to eq(10 => 0.25)
    end

    it "rebuilds the throttle cache from authoritative DB state across multiple disables" do
      c1 = BillboardCampaign.create!(name: "C1", ideal_daily_impressions: 5_000, delivery_throttle_rate: 0.2)
      c2 = BillboardCampaign.create!(name: "C2", ideal_daily_impressions: 5_000, delivery_throttle_rate: 0.4)
      c3 = BillboardCampaign.create!(name: "C3", ideal_daily_impressions: 5_000, delivery_throttle_rate: 0.6)

      described_class.refresh_throttled_campaign_rates_cache!
      expect(described_class.throttled_campaign_rates).to eq(c1.id => 0.2, c2.id => 0.4, c3.id => 0.6)

      c1.update!(ideal_daily_impressions: 0)
      c2.update!(ideal_daily_impressions: 0)

      expect(described_class.throttled_campaign_rates).to eq(c3.id => 0.6)
    end
  end
end
