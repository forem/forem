module Billboards
  # Encapsulates campaign impression titration math and the serving-time throttle cache.
  #
  # Campaigns are steered smoothly across three monotonic delivery levers:
  # 1. `delivery_throttle_rate` (0.0..1.0): probabilistic admission gate in FilteredAdsQuery,
  #    engaged only when a campaign still over-delivers after priority is off and weight is low
  #    (e.g. high-CTR billboards picked heavily by `weighted_performance`).
  # 2. `Billboard#priority` (boolean): controls membership in the `new_and_priority` weighted pool.
  # 3. `Billboard#weight` (0.01..10_000.0): scales relative share inside `new_and_priority`.
  class CampaignPacing
    WINDOW_DURATION = 10.minutes
    WINDOWS_PER_DAY = 144.0

    THROTTLE_CACHE_KEY = "billboards:throttled_campaign_rates:v1".freeze
    THROTTLE_CACHE_EXPIRY = 30.minutes
    THROTTLE_MEMORY_EXPIRY = 1.minute

    SMOOTHING_PRIOR = 3.0
    DEADBAND_LOW = 0.90
    DEADBAND_HIGH = 1.10
    CONTROL_GAIN = 0.6
    MAX_UP_FACTOR = 4.0
    MIN_DOWN_FACTOR = 0.25

    MIN_WEIGHT = 0.01
    MAX_WEIGHT = 10_000.0
    PRIORITY_OFF_WEIGHT_THRESHOLD = 1.0

    MIN_OPEN_THROTTLE_RATE = 0.05
    MIN_NONZERO_THROTTLE_RATE = 0.01
    FULL_THROTTLE_SNAP_THRESHOLD = 0.98

    Result = Data.define(:throttle_rate, :billboard_updates)
    BillboardUpdate = Data.define(:id, :weight, :priority)

    class << self
      # Returns a hash of `{ campaign_id (Integer) => pass_through_rate (Float < 1.0) }`
      # served from L1 in-process memory to avoid per-request Redis round-trips.
      # Never writes back to Redis on a miss so concurrent readers cannot race with the writer.
      def throttled_campaign_rates
        cached = MemoryFirstCache.fetch(THROTTLE_CACHE_KEY, memory_expires_in: THROTTLE_MEMORY_EXPIRY)
        return {} unless cached.is_a?(Hash) && cached.any?

        cached.each_with_object({}) do |(campaign_id, rate), hash|
          rate_f = rate.to_f
          hash[campaign_id.to_i] = rate_f if rate_f < 1.0
        end
      end

      # Returns campaign IDs to exclude from the current billboard request based on each
      # throttled campaign's pass-through probability. Fast-paths to `[]` with zero allocations
      # when no campaigns are throttled.
      def excluded_campaign_ids(rng: Kernel)
        rates = throttled_campaign_rates
        return [] if rates.empty?

        rates.each_with_object([]) do |(campaign_id, rate), excluded|
          excluded << campaign_id if rate <= 0.0 || rng.rand >= rate
        end
      end

      def write_throttled_campaign_rates(rates)
        sanitized = {}
        rates.each do |campaign_id, rate|
          rate_f = rate.to_f.clamp(0.0, 1.0).round(4)
          sanitized[campaign_id.to_i] = rate_f if rate_f < 1.0
        end

        MemoryFirstCache.write(
          THROTTLE_CACHE_KEY,
          sanitized,
          memory_expires_in: THROTTLE_MEMORY_EXPIRY,
          redis_expires_in: THROTTLE_CACHE_EXPIRY,
        )
      end

      # Rebuilds and atomically publishes the throttle map from the authoritative database state,
      # preventing concurrent disable callbacks or stale worker snapshots from resurrecting disabled campaigns.
      def refresh_throttled_campaign_rates_cache!(now: Time.current)
        active_rates = BillboardCampaign
          .with_ideal_daily_impressions
          .where("expires_at IS NULL OR expires_at > ?", now)
          .where("delivery_throttle_rate < 1.0")
          .pluck(:id, :delivery_throttle_rate)
          .to_h

        write_throttled_campaign_rates(active_rates)
      end

      def expected_window_impressions(ideal_daily_impressions, traffic_multiplier: 1.0)
        return 0.0 unless ideal_daily_impressions.to_i.positive?

        (ideal_daily_impressions.to_f / WINDOWS_PER_DAY) * traffic_multiplier.to_f
      end

      # Computes the next lever states for a single campaign given its 10-minute actual impressions
      # and traffic-adjusted expected impressions.
      def calculate_adjustments(ideal_daily_impressions:, actual_impressions:, traffic_multiplier:,
                                current_throttle_rate:, billboards:)
        rate = current_throttle_rate.to_f.clamp(0.0, 1.0)
        expected = expected_window_impressions(ideal_daily_impressions, traffic_multiplier: traffic_multiplier)
        return Result.new(throttle_rate: rate, billboard_updates: []) if expected <= 0.0 || billboards.empty?

        # Never let the smoothing deadband hold a hard-paused campaign closed when it has positive
        # expected delivery and received zero impressions.
        if rate <= 0.0 && actual_impressions.to_f <= 0.0
          return Result.new(throttle_rate: MIN_OPEN_THROTTLE_RATE, billboard_updates: [])
        end

        ratio = (actual_impressions.to_f + SMOOTHING_PRIOR) / (expected + SMOOTHING_PRIOR)
        return Result.new(throttle_rate: rate, billboard_updates: []) if ratio.between?(DEADBAND_LOW, DEADBAND_HIGH)

        factor = (ratio**-CONTROL_GAIN).clamp(MIN_DOWN_FACTOR, MAX_UP_FACTOR)

        if ratio < DEADBAND_LOW
          adjust_up(rate, factor, billboards)
        else
          adjust_down(rate, factor, billboards)
        end
      end

      private

      def adjust_up(current_rate, factor, billboards)
        if current_rate < 1.0
          new_rate = if current_rate <= 0.0
                       MIN_OPEN_THROTTLE_RATE
                     else
                       (current_rate * factor).round(4)
                     end
          new_rate = 1.0 if new_rate >= FULL_THROTTLE_SNAP_THRESHOLD
          return Result.new(throttle_rate: new_rate, billboard_updates: [])
        end

        any_positive_weight = billboards.any? { |bb| bb.weight.to_f.positive? }
        updates = billboards.filter_map do |bb|
          current_weight = bb.weight.to_f
          # Preserve explicit 0.0 manual mutes when other creatives in the campaign are active.
          next if current_weight <= 0.0 && any_positive_weight

          base_weight = [current_weight, MIN_WEIGHT].max
          new_weight = (base_weight * factor).clamp(MIN_WEIGHT, MAX_WEIGHT).round(4)
          new_priority = true
          next if new_weight == current_weight && bb.priority == new_priority

          BillboardUpdate.new(id: bb.id, weight: new_weight, priority: new_priority)
        end

        Result.new(throttle_rate: 1.0, billboard_updates: updates)
      end

      def adjust_down(current_rate, factor, billboards)
        if current_rate < 1.0
          new_rate = tighten_throttle_rate(current_rate, factor)
          updates = force_billboards_to_floor(billboards)
          return Result.new(throttle_rate: new_rate, billboard_updates: updates)
        end

        if priority_and_weight_exhausted?(billboards)
          new_rate = tighten_throttle_rate(1.0, factor)
          updates = force_billboards_to_floor(billboards)
          return Result.new(throttle_rate: new_rate, billboard_updates: updates)
        end

        updates = billboards.filter_map do |bb|
          current_weight = bb.weight.to_f
          next if current_weight <= 0.0 && !bb.priority

          new_weight = current_weight.positive? ? (current_weight * factor).clamp(MIN_WEIGHT, MAX_WEIGHT).round(4) : 0.0
          new_priority = bb.priority && new_weight > PRIORITY_OFF_WEIGHT_THRESHOLD
          next if new_weight == current_weight && bb.priority == new_priority

          BillboardUpdate.new(id: bb.id, weight: new_weight, priority: new_priority)
        end

        Result.new(throttle_rate: 1.0, billboard_updates: updates)
      end

      def tighten_throttle_rate(current_rate, factor)
        new_rate = (current_rate * factor).clamp(0.0, 1.0).round(4)
        new_rate < MIN_NONZERO_THROTTLE_RATE ? 0.0 : new_rate
      end

      def priority_and_weight_exhausted?(billboards)
        billboards.all? { |bb| !bb.priority && bb.weight.to_f <= PRIORITY_OFF_WEIGHT_THRESHOLD }
      end

      def force_billboards_to_floor(billboards)
        billboards.filter_map do |bb|
          current_weight = bb.weight.to_f
          target_weight = current_weight.positive? ? [current_weight, MIN_WEIGHT].min : 0.0
          next if target_weight == current_weight && !bb.priority

          BillboardUpdate.new(id: bb.id, weight: target_weight, priority: false)
        end
      end
    end
  end
end
