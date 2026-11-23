module Billboards
  # Estimates relative billboard impression traffic across the 7x24 (day-of-week x hour-of-day, UTC)
  # weekly cycle using a bounded primary-key stride sample over the past few weeks of
  # `display_ad_events`.
  #
  # Because `display_ad_events` is append-only over the last 3 weeks (rollups only compact rows
  # older than 1 month), sampling evenly spaced primary-key IDs across `[min_id, max_id]` produces
  # bucket counts directly proportional to impression volume while touching at most SAMPLE_SIZE
  # primary-key rows instead of scanning millions of rows.
  #
  # The resulting 7x24 matrix has a grand mean of 1.0 (so integrating across a full week equals
  # exactly 7 * ideal_daily_impressions) and is cached for days at a time.
  class TrafficProfile
    CACHE_KEY = "billboards:traffic_profile:v1".freeze
    CACHE_EXPIRY = 3.days
    FALLBACK_CACHE_EXPIRY = 15.minutes
    LOOKBACK_WEEKS = 3
    SAMPLE_SIZE = 10_000
    DAYS_PER_WEEK = 7
    HOURS_PER_DAY = 24
    SLOTS_PER_WEEK = DAYS_PER_WEEK * HOURS_PER_DAY
    DAY_PRIOR_WEIGHT = 100.0
    HOUR_PRIOR_WEIGHT = 50.0
    CELL_PRIOR_WEIGHT = 50.0
    MIN_MULTIPLIER = 0.25
    MAX_MULTIPLIER = 3.0
    NORMALIZATION_PASSES = 5
    STATEMENT_TIMEOUT = ENV.fetch("STATEMENT_TIMEOUT_BILLBOARD_TRAFFIC_PROFILE", 15_000).to_i

    UNIFORM_MATRIX = Array.new(DAYS_PER_WEEK) { Array.new(HOURS_PER_DAY, 1.0).freeze }.freeze

    class << self
      def multiplier_for(time = Time.current)
        matrix = fetch(now: time)
        utc = time.utc
        value = matrix.dig(utc.wday, utc.hour)
        value.is_a?(Numeric) && value.positive? ? value.to_f : 1.0
      end

      def fetch(now: Time.current)
        cached = Rails.cache.read(CACHE_KEY)
        return cached if valid_matrix?(cached)

        refresh!(now: now)
      end

      def refresh!(now: Time.current)
        matrix = compute(now: now)
        Rails.cache.write(CACHE_KEY, matrix, expires_in: CACHE_EXPIRY)
        matrix
      rescue ActiveRecord::QueryCanceled, ActiveRecord::StatementInvalid => e
        Rails.logger.warn("Billboards::TrafficProfile refresh failed (#{e.class}): #{e.message}")
        Rails.cache.write(CACHE_KEY, UNIFORM_MATRIX, expires_in: FALLBACK_CACHE_EXPIRY)
        UNIFORM_MATRIX
      end

      def compute(now: Time.current)
        # Align to an exact multiple of 7 days so every (dow, hour) slot appears the same number of times.
        window_end = now.utc.beginning_of_hour
        window_start = window_end - LOOKBACK_WEEKS.weeks

        counts = nil
        ReadOnlyDatabaseService.with_connection do |conn|
          conn.transaction do
            conn.execute("SET LOCAL statement_timeout TO #{STATEMENT_TIMEOUT}")
            counts = sample_impression_counts(conn, window_start, window_end)
          end
        end

        build_matrix(counts)
      end

      # Builds a normalized 7x24 multiplier matrix from raw (dow, hour) sample counts using
      # hierarchical Empirical Bayes shrinkage:
      # 1. Day-of-week and hour-of-day marginals are shrunk gently toward 1.0.
      # 2. Each (dow, hour) cell is shrunk toward its factorized D[dow] * H[hour] prior.
      # 3. Values are clamped to [MIN_MULTIPLIER, MAX_MULTIPLIER] and re-normalized to mean 1.0.
      def build_matrix(counts)
        return UNIFORM_MATRIX if counts.nil?

        total = counts.sum { |row| row.sum.to_f }
        return UNIFORM_MATRIX unless total.positive?

        day_weights = compute_day_weights(counts, total)
        hour_weights = compute_hour_weights(counts, total)
        raw_matrix = compute_shrunk_cells(counts, total, day_weights, hour_weights)

        normalize_and_clamp(raw_matrix)
      end

      private

      def valid_matrix?(matrix)
        matrix.is_a?(Array) &&
          matrix.length == DAYS_PER_WEEK &&
          matrix.all? { |row| row.is_a?(Array) && row.length == HOURS_PER_DAY }
      end

      def sample_impression_counts(conn, window_start, window_end)
        max_id = fetch_max_id(conn)
        return unless max_id

        min_id = find_window_min_id(conn, window_start, window_end)
        return unless min_id && min_id <= max_id

        stride = [((max_id - min_id) / SAMPLE_SIZE), 1].max
        counts = Array.new(DAYS_PER_WEEK) { Array.new(HOURS_PER_DAY, 0) }

        # display_ad_events.created_at is `timestamp without time zone` stored in UTC by Rails,
        # so EXTRACT(DOW/HOUR FROM e.created_at) reads UTC wall-clock fields directly without
        # depending on the database session's TimeZone setting.
        sql = <<~SQL.squish
          SELECT
            EXTRACT(DOW FROM e.created_at)::int AS dow,
            EXTRACT(HOUR FROM e.created_at)::int AS hour,
            SUM(e.counts_for)::bigint AS sample_impressions
          FROM generate_series(#{min_id.to_i}, #{max_id.to_i}, #{stride.to_i}) AS s(id)
          INNER JOIN display_ad_events e ON e.id = s.id
          WHERE e.category = #{conn.quote(BillboardEvent::CATEGORY_IMPRESSION)}
            AND e.created_at >= #{conn.quote(window_start)}
            AND e.created_at < #{conn.quote(window_end)}
          GROUP BY 1, 2
        SQL

        conn.execute(sql).each do |row|
          dow = row["dow"].to_i
          hour = row["hour"].to_i
          next unless dow.between?(0, DAYS_PER_WEEK - 1) && hour.between?(0, HOURS_PER_DAY - 1)

          counts[dow][hour] = row["sample_impressions"].to_i
        end

        counts
      end

      def fetch_max_id(conn)
        row = conn.execute("SELECT MAX(id) AS max_id FROM display_ad_events").first
        row && row["max_id"]&.to_i
      end

      def find_window_min_id(conn, window_start, window_end)
        # Progressively widen the BRIN probe window so busy databases touch only ~1-2 BRIN ranges
        # around window_start while sparse/new databases still find the first in-window event.
        probe_ends = [
          [window_start + 1.hour, window_end].min,
          [window_start + 1.day, window_end].min,
          window_end,
        ].uniq

        probe_ends.each do |probe_end|
          # `MIN(id + 0)` disables PostgreSQL's minmax index-scan rewrite, which would otherwise
          # walk `display_ad_events_pkey` forward from row 1 instead of using the `created_at` BRIN index.
          sql = <<~SQL.squish
            SELECT MIN(id + 0) AS min_id
            FROM display_ad_events
            WHERE created_at >= #{conn.quote(window_start)}
              AND created_at < #{conn.quote(probe_end)}
          SQL
          min_id = conn.execute(sql).first&.dig("min_id")
          return min_id.to_i if min_id.present?
        end

        nil
      end

      def compute_day_weights(counts, total)
        avg_per_day = total / DAYS_PER_WEEK.to_f
        raw = counts.map { |row| (row.sum.to_f + DAY_PRIOR_WEIGHT) / (avg_per_day + DAY_PRIOR_WEIGHT) }
        mean = raw.sum / DAYS_PER_WEEK.to_f
        raw.map { |w| w / mean }
      end

      def compute_hour_weights(counts, total)
        avg_per_hour = total / HOURS_PER_DAY.to_f
        raw = Array.new(HOURS_PER_DAY) do |hour|
          hour_sum = counts.sum { |row| row[hour].to_f }
          (hour_sum + HOUR_PRIOR_WEIGHT) / (avg_per_hour + HOUR_PRIOR_WEIGHT)
        end
        mean = raw.sum / HOURS_PER_DAY.to_f
        raw.map { |w| w / mean }
      end

      def compute_shrunk_cells(counts, total, day_weights, hour_weights)
        avg_per_cell = total / SLOTS_PER_WEEK.to_f
        denom = avg_per_cell + CELL_PRIOR_WEIGHT

        Array.new(DAYS_PER_WEEK) do |dow|
          Array.new(HOURS_PER_DAY) do |hour|
            prior = day_weights[dow] * hour_weights[hour]
            (counts[dow][hour].to_f + (CELL_PRIOR_WEIGHT * prior)) / denom
          end
        end
      end

      def normalize_and_clamp(matrix)
        current = matrix.map { |row| row.map { |v| v.clamp(MIN_MULTIPLIER, MAX_MULTIPLIER) } }

        NORMALIZATION_PASSES.times do
          mean = current.sum(&:sum) / SLOTS_PER_WEEK.to_f
          break if mean <= 0.0

          current = current.map { |row| row.map { |v| (v / mean).clamp(MIN_MULTIPLIER, MAX_MULTIPLIER) } }
        end

        current.map { |row| row.map { |v| v.round(4) } }
      end
    end
  end
end
