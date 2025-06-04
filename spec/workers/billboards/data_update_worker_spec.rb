# spec/workers/billboards/data_update_worker_spec.rb
require "rails_helper"
require "sidekiq/testing"

RSpec.describe Billboards::DataUpdateWorker, type: :worker do
  let(:worker) { described_class.new }
  let(:billboard) { create(:billboard) }

  before do
    # Use fake mode so we can inspect jobs, but we'll call perform_inline for actual logic
    Sidekiq::Testing.inline!
  end

  context "when counts_tabulated_at is nil (first-time tabulation)" do
    before do
      # Create 3 impressions and 2 clicks, all before calling worker
      create_list(:billboard_event, 3, billboard: billboard, category: "impression", counts_for: 2)
      create_list(:billboard_event, 2, billboard: billboard, category: "click",     counts_for: 1)

      # Also create 1 conversion event
      create(:billboard_event, billboard: billboard, category: "conversion", counts_for: 4)
    end

    it "sets clicks_count, impressions_count, success_rate, and counts_tabulated_at" do
      expect(billboard.counts_tabulated_at).to be_nil

      # Force the update to skip random/throttle
      worker.perform(billboard.id, forced: true)
      billboard.reload

      # impressions: 3 events × 2 each = 6
      expect(billboard.impressions_count).to eq(6)

      # clicks: 2 events × 1 each = 2
      expect(billboard.clicks_count).to eq(2)

      # conversion_success: 1 event × 4 × CONVERSION_SUCCESS_MODIFIER (25) = 100
      total_clicks = 2
      total_conversion = 4 * described_class::CONVERSION_SUCCESS_MODIFIER
      expected_rate = (total_clicks + total_conversion).to_f / 6

      expect(billboard.success_rate).to eq(expected_rate)
      expect(billboard.counts_tabulated_at).to be_present
    end
  end

  context "when counts_tabulated_at is already set (incremental update)" do
    let(:old_timestamp) { 2.hours.ago }

    before do
      # Set an initial counts_tabulated_at and initial counts on the billboard
      billboard.update_columns(
        impressions_count: 5,
        clicks_count:      2,
        success_rate:      0.0,
        counts_tabulated_at: old_timestamp
      )

      # Create some “older” events—these should be ignored
      create(:billboard_event, billboard: billboard, category: "impression", counts_for: 10, created_at: old_timestamp - 1.day)
      create(:billboard_event, billboard: billboard, category: "click",     counts_for:  3, created_at: old_timestamp - 1.day)
      create(:billboard_event, billboard: billboard, category: "conversion", counts_for:  1, created_at: old_timestamp - 1.day)

      # Create “new” events—these should be picked up in the incremental pass
      create(:billboard_event, billboard: billboard, category: "impression", counts_for: 4, created_at: old_timestamp + 1.minute)
      create(:billboard_event, billboard: billboard, category: "click",     counts_for: 2, created_at: old_timestamp + 2.minutes)
      create(:billboard_event, billboard: billboard, category: "conversion", counts_for: 3, created_at: old_timestamp + 3.minutes)
    end

    it "adds only new events and updates counts_tabulated_at" do
      first_counts = {
        impressions: billboard.impressions_count,
        clicks: billboard.clicks_count
      }
      expect(first_counts[:impressions]).to eq(5)
      expect(first_counts[:clicks]).to eq(2)

      # Force the update
      worker.perform(billboard.id, forced: true)
      billboard.reload

      # New impressions: 4 => total should be 5 + 4 = 9
      expect(billboard.impressions_count).to eq(9)

      # New clicks: 2 => total should be 2 + 2 = 4
      expect(billboard.clicks_count).to eq(4)

      # Conversion_success: 3 * 25 = 75
      new_total_clicks = 4          # 2 (old) + 2 (new)
      conversion_success = 3 * described_class::CONVERSION_SUCCESS_MODIFIER
      expected_rate = (new_total_clicks + conversion_success).to_f / 9

      expect(billboard.success_rate).to eq(expected_rate)
      expect(billboard.counts_tabulated_at).to be > old_timestamp
    end
  end

  context "when not forced (default), random‐skip and throttle logic applies" do
    before do
      # Reset to fake mode so we can stub ThrottledCall
      Sidekiq::Testing.fake!
    end

    it "does NOT perform update if ThrottledCall blocks it" do
      # Stub ThrottledCall.perform to never yield the block
      allow(ThrottledCall).to receive(:perform).and_return(nil)

      # No events exist, but we only care that perform_update is never invoked
      expect(billboard.clicks_count).to eq(0)
      expect(billboard.impressions_count).to eq(0)

      # This should not raise, but also should not change any counts
      worker.perform(billboard.id)
      billboard.reload

      expect(billboard.clicks_count).to eq(0)
      expect(billboard.impressions_count).to eq(0)
    end

    it "skips the update if random-skip conditions hit" do
      # Force counts so the random‐skip condition is testable
      billboard.update_columns(impressions_count: 600_000, clicks_count: 0, counts_tabulated_at: nil)

      # Stub rand so that rand(3) > 0 (for example, rand(3) returns 2)
      allow_any_instance_of(described_class).to receive(:rand).with(3).and_return(2)
      allow(ThrottledCall).to receive(:perform) do |key, opts, &block|
        # We want ThrottledCall.perform to yield (so we hit the random‐skip inside)
        block.call
      end

      # Because impressions_count > 500_000 and rand(3) > 0, the update should return early
      worker.perform(billboard.id)
      billboard.reload

      # Still zero counts (since we never actually created events)
      expect(billboard.impressions_count).to eq(600_000)
      expect(billboard.clicks_count).to eq(0)
      expect(billboard.success_rate).to eq(0.0).or be_nil
    end
  end
end
