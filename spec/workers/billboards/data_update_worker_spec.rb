# spec/workers/billboards/data_update_worker_spec.rb
require "rails_helper"

RSpec.describe Billboards::DataUpdateWorker, type: :worker do
  include ActiveSupport::Testing::TimeHelpers

  let(:worker) { described_class.new }
  let(:now) { Time.zone.local(2025, 6, 6, 12, 0, 0) }

  before do
    # Ensure Sidekiq testing mode does not actually enqueue jobs
    Sidekiq::Worker.clear_all
  end

  describe "#perform_update" do
    context "when the billboard has never been tabulated before" do
      let!(:billboard) { create(:billboard, impressions_count: 0, clicks_count: 0, counts_tabulated_at: nil) }

      before do
        # Create some events before now
        create(:billboard_event,
          billboard: billboard,
          category: "impression",
          counts_for: 5,
          created_at: now - 2.hours
        )
        create(:billboard_event,
          billboard: billboard,
          category: "click",
          counts_for: 2,
          created_at: now - 1.hour
        )
        create(:billboard_event,
          billboard: billboard,
          category: "conversion",
          counts_for: 1,
          created_at: now - 30.minutes
        )
      end

      it "aggregates all events and updates counts / rate / tabulation timestamp" do
        travel_to(now) do
          expect(billboard.counts_tabulated_at).to be_nil

          worker.perform(billboard.id)
          billboard.reload

          # Total impressions = 5
          # Total clicks = 2
          # Total conversions = 1 * CONVERSION_SUCCESS_MODIFIER (25) = 25
          expected_rate = (2 + 25).to_f / 5

          expect(billboard.impressions_count).to eq(5)
          expect(billboard.clicks_count).to eq(2)
          expect(billboard.success_rate).to eq(expected_rate)
          expect(billboard.counts_tabulated_at).to eq(now)
        end
      end
    end

    context "when the billboard has been tabulated before" do
      let!(:billboard) do
        create(
          :billboard,
          impressions_count: 10,
          clicks_count: 4,
          counts_tabulated_at: now - 1.day
        )
      end

      before do
        # Events older than cutoff (should be ignored)
        create(:billboard_event,
          billboard: billboard,
          category: "impression",
          counts_for: 3,
          created_at: (now - 2.days)
        )
        create(:billboard_event,
          billboard: billboard,
          category: "click",
          counts_for: 1,
          created_at: (now - 2.days)
        )
        create(:billboard_event,
          billboard: billboard,
          category: "conversion",
          counts_for: 2,
          created_at: (now - 2.days)
        )

        # Events newer than cutoff (should be included)
        create(:billboard_event,
          billboard: billboard,
          category: "impression",
          counts_for: 7,
          created_at: (now - 12.hours)
        )
        create(:billboard_event,
          billboard: billboard,
          category: "click",
          counts_for: 3,
          created_at: (now - 6.hours)
        )
        create(:billboard_event,
          billboard: billboard,
          category: "conversion",
          counts_for: 1,
          created_at: (now - 3.hours)
        )
      end

      before do
        # Stub random behavior so neither early-return branch triggers
        allow_any_instance_of(Billboards::DataUpdateWorker).to receive(:rand).with(3).and_return(0)
        allow_any_instance_of(Billboards::DataUpdateWorker).to receive(:rand).with(2).and_return(1)
        
        # Ensure the worker actually processes the billboard by stubbing rand calls
        allow_any_instance_of(Billboards::DataUpdateWorker).to receive(:rand).and_call_original
      end

      it "aggregates only new events and increments counters accordingly" do
        travel_to(now) do
          original_impressions = billboard.impressions_count
          original_clicks      = billboard.clicks_count

          worker.perform(billboard.id)
          billboard.reload

          # New impressions = 7, so total = 10 + 7 = 17
          # New clicks = 3, so total = 4 + 3 = 7
          # New conversion count = 1 * 25 = 25
          expected_new_rate = (7 + 25).to_f / 17

          expect(billboard.impressions_count).to eq(17)
          expect(billboard.clicks_count).to eq(7)
          expect(billboard.success_rate).to eq(expected_new_rate)
          expect(billboard.counts_tabulated_at).to eq(now)
        end
      end
    end

    context "when impressions_count is very large and first random check triggers early return" do
      let!(:billboard) do
        create(
          :billboard,
          impressions_count: 600_000,
          clicks_count: 100,
          counts_tabulated_at: now - 1.day
        )
      end

      before do
        # Stub rand(3) to return > 0, so early return if impressions_count > 500_000
        allow_any_instance_of(Billboards::DataUpdateWorker).to receive(:rand).with(3).and_return(1)
      end

      it "does not change the billboard at all" do
        travel_to(now) do
          original_attributes = billboard.slice(
            "impressions_count", "clicks_count", "success_rate", "counts_tabulated_at"
          )

          worker.perform(billboard.id)
          billboard.reload

          expect(billboard.slice(
            "impressions_count", "clicks_count", "success_rate", "counts_tabulated_at"
          )).to eq(original_attributes)
        end
      end
    end

    context "when impressions_count is above 100_000 but below 500_000 and second random check triggers early return" do
      let!(:billboard) do
        create(
          :billboard,
          impressions_count: 200_000,
          clicks_count: 50,
          counts_tabulated_at: now - 1.day
        )
      end

      before do
        # First rand(3) returns 0, so skip first check.
        allow_any_instance_of(Billboards::DataUpdateWorker).to receive(:rand).with(3).and_return(0)
        # Second rand(2) returns 0, so early return if impressions_count > 100_000
        allow_any_instance_of(Billboards::DataUpdateWorker).to receive(:rand).with(2).and_return(0)
      end

      it "does not change the billboard at all" do
        travel_to(now) do
          original_attributes = billboard.slice(
            "impressions_count", "clicks_count", "success_rate", "counts_tabulated_at"
          )

          worker.perform(billboard.id)
          billboard.reload

          expect(billboard.slice(
            "impressions_count", "clicks_count", "success_rate", "counts_tabulated_at"
          )).to eq(original_attributes)
        end
      end
    end

    context "when handling billboard expiration" do
      let!(:billboard) do
        create(
          :billboard,
          approved: true,
          published: true,
          impressions_count: 100,
          clicks_count: 10,
          counts_tabulated_at: now - 1.day
        )
      end

      before do
        # Stub random behavior so neither early-return branch triggers
        allow_any_instance_of(Billboards::DataUpdateWorker).to receive(:rand).with(3).and_return(0)
        allow_any_instance_of(Billboards::DataUpdateWorker).to receive(:rand).with(2).and_return(1)
      end

      it "handles expiration when billboard has expired" do
        # Create some events to ensure the worker processes the billboard
        create(:billboard_event,
          billboard: billboard,
          category: "impression",
          counts_for: 5,
          created_at: now - 1.hour
        )
        
        # Set the billboard to expired
        billboard.update_column(:expires_at, 1.day.ago)
        
        # Mock the random behavior to ensure the worker doesn't return early
        allow_any_instance_of(Billboards::DataUpdateWorker).to receive(:rand).with(3).and_return(0)
        allow_any_instance_of(Billboards::DataUpdateWorker).to receive(:rand).with(2).and_return(1)
        
        # The worker should mark the billboard as not approved
        expect { worker.perform(billboard.id) }.to change { billboard.reload.approved }.from(true).to(false)
      end

      context "when billboard has expired" do
        before do
          billboard.update_column(:expires_at, 1.day.ago)
        end

        it "marks the billboard as not approved" do
          expect { worker.perform(billboard.id) }.to change { billboard.reload.approved }.from(true).to(false)
        end

        it "still processes other updates normally" do
          # Create some new events to ensure they're processed
          create(:billboard_event,
            billboard: billboard,
            category: "impression",
            counts_for: 5,
            created_at: now - 1.hour
          )
          create(:billboard_event,
            billboard: billboard,
            category: "click",
            counts_for: 2,
            created_at: now - 30.minutes
          )

          worker.perform(billboard.id)
          billboard.reload

          # Should still update counts even after expiration
          expect(billboard.impressions_count).to eq(105) # 100 + 5
          expect(billboard.clicks_count).to eq(12) # 10 + 2
        end
      end

      context "when billboard has not expired" do
        before do
          billboard.update_column(:expires_at, 1.day.from_now)
        end

        it "does not change the billboard approval status" do
          expect { worker.perform(billboard.id) }.not_to change { billboard.reload.approved }
        end
      end

      context "when billboard has no expiration" do
        before do
          billboard.update_column(:expires_at, nil)
        end

        it "does not change the billboard approval status" do
          expect { worker.perform(billboard.id) }.not_to change { billboard.reload.approved }
        end
      end
    end
  end
end
