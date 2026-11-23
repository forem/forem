require "rails_helper"

RSpec.describe Billboards::TrafficProfile do
  include ActiveSupport::Testing::TimeHelpers

  before do
    allow(Rails).to receive(:cache).and_return(ActiveSupport::Cache::MemoryStore.new)
    Rails.cache.clear
  end

  describe ".build_matrix" do
    it "returns a uniform matrix when counts are nil or all zero" do
      expect(described_class.build_matrix(nil)).to eq(described_class::UNIFORM_MATRIX)

      empty = Array.new(7) { Array.new(24, 0) }
      expect(described_class.build_matrix(empty)).to eq(described_class::UNIFORM_MATRIX)
    end

    it "returns 1.0 everywhere for perfectly uniform counts" do
      uniform = Array.new(7) { Array.new(24, 100) }
      matrix = described_class.build_matrix(uniform)

      expect(matrix.flatten.uniq).to eq([1.0])
    end

    it "reflects day-of-week and hour-of-day skew with grand mean ~1.0 and bounded entries" do
      # Simulate heavy weekday (Mon-Fri) afternoon (12..19 UTC) and quiet weekends (Sun, Sat) nights (0..7 UTC)
      counts = Array.new(7) do |dow|
        day_scale = dow.between?(1, 5) ? 2.0 : 0.5
        Array.new(24) do |hour|
          hour_scale = if hour.between?(12, 19)
                         2.5
                       elsif hour.between?(0, 7)
                         0.4
                       else
                         1.0
                       end
          (50 * day_scale * hour_scale).round
        end
      end

      matrix = described_class.build_matrix(counts)
      flat = matrix.flatten

      expect(flat.sum / flat.size).to be_within(0.01).of(1.0)
      expect(flat.min).to be >= described_class::MIN_MULTIPLIER
      expect(flat.max).to be <= described_class::MAX_MULTIPLIER

      # Peak weekday afternoon should be significantly higher than quiet Sunday night
      expect(matrix[2][15]).to be > 1.5
      expect(matrix[0][3]).to be < 0.5
      expect(matrix[2][15]).to be > matrix[0][15]
      expect(matrix[2][15]).to be > matrix[2][3]
    end

    it "shrinks sparse samples gently toward 1.0 instead of overfitting noise" do
      counts = Array.new(7) { Array.new(24, 0) }
      counts[3][14] = 5

      matrix = described_class.build_matrix(counts)

      expect(matrix[3][14]).to be > 1.0
      expect(matrix[3][14]).to be < 1.3
      expect(matrix.flatten.min).to be > 0.8
    end
  end

  describe ".compute, .fetch, and .multiplier_for" do
    # Wednesday 2026-11-18 15:00:00 UTC (wday = 3, hour = 15)
    let(:now) { Time.utc(2026, 11, 18, 15, 30, 0) }
    let(:billboard) { create(:billboard) }

    before do
      # Baseline traffic distributed across days and hours so the mean is well-defined
      7.times do |day_offset|
        [2, 8, 14, 20].each do |hour|
          ts = Time.utc(2026, 11, 10, hour, 15, 0) + day_offset.days
          create(:billboard_event, billboard: billboard, category: "impression", counts_for: 100, created_at: ts)
        end
      end

      # Heavy traffic on Tuesdays at 14:00 UTC (wday 2) and light on Sundays at 04:00 UTC (wday 0)
      [0, 7, 14].each do |days_back|
        peak_ts = Time.utc(2026, 11, 17, 14, 20, 0) - days_back.days
        create(:billboard_event, billboard: billboard, category: "impression", counts_for: 500, created_at: peak_ts)

        quiet_ts = Time.utc(2026, 11, 15, 4, 15, 0) - days_back.days
        create(:billboard_event, billboard: billboard, category: "impression", counts_for: 5, created_at: quiet_ts)
      end

      # Non-impression events should be ignored
      create(:billboard_event, billboard: billboard, category: "click", counts_for: 5_000,
                               created_at: Time.utc(2026, 11, 15, 4, 20, 0))

      # Events older than the 3-week lookback window should be ignored
      create(:billboard_event, billboard: billboard, category: "impression", counts_for: 5_000,
                               created_at: now - 4.weeks)
    end

    it "samples impressions from the past 3 weeks and produces relative multipliers" do
      travel_to(now) do
        tuesday_peak = described_class.multiplier_for(Time.utc(2026, 11, 17, 14, 0, 0))
        sunday_quiet = described_class.multiplier_for(Time.utc(2026, 11, 15, 4, 0, 0))

        expect(tuesday_peak).to be > 1.5
        expect(sunday_quiet).to be < tuesday_peak
      end
    end

    it "uses MIN(id + 0) for window start probes so PostgreSQL uses the created_at BRIN index" do
      executed_sql = []
      allow(ReadOnlyDatabaseService).to receive(:with_connection).and_wrap_original do |original, &block|
        original.call do |conn|
          allow(conn).to receive(:execute).and_wrap_original do |exec_orig, sql, *args|
            executed_sql << sql
            exec_orig.call(sql, *args)
          end
          block.call(conn)
        end
      end

      travel_to(now) { described_class.compute(now: now) }

      probe_queries = executed_sql.grep(/AS min_id/)
      expect(probe_queries).not_to be_empty
      expect(probe_queries).to all(include("MIN(id + 0)"))
    end

    it "caches the computed profile for multiple days and avoids recomputing on subsequent reads" do
      travel_to(now) do
        first = described_class.fetch(now: now)
        expect(Rails.cache.read(described_class::CACHE_KEY)).to eq(first)

        allow(described_class).to receive(:compute).and_call_original
        second = described_class.fetch(now: now + 2.days)

        expect(second).to eq(first)
        expect(described_class).not_to have_received(:compute)
      end
    end

    it "falls back to uniform multipliers with a short TTL when the database query times out" do
      allow(described_class).to receive(:compute).and_raise(ActiveRecord::QueryCanceled.new("statement timeout"))

      travel_to(now) do
        result = described_class.fetch(now: now)

        expect(result).to eq(described_class::UNIFORM_MATRIX)
        expect(described_class.multiplier_for(now)).to eq(1.0)
      end
    end
  end
end
