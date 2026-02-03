require "rails_helper"

RSpec.describe Organizations::TrackPromotionalBillboardImpressionsWorker, type: :worker do
  include ActiveSupport::Testing::TimeHelpers

  let(:worker) { described_class.new }
  let(:now) { Time.zone.local(2025, 11, 25, 12, 0, 0) }

  before do
    Sidekiq::Worker.clear_all
    # Use memory store for tests to ensure cache operations work
    allow(Rails).to receive(:cache).and_return(ActiveSupport::Cache::MemoryStore.new)
    Rails.cache.clear
  end

  describe "#perform" do
    context "when organization has tracking enabled" do
      let(:organization) do
        create(:organization,
               ideal_daily_promoted_billboard_impressions: 1000,
               past_24_hours_promoted_billboard_impressions: 0,
               currently_paused_promotional_billboards: false)
      end

      let(:billboard) { create(:billboard, organization: organization) }

      context "when impressions are within limit" do
        before do
          # Create impressions within the past 24 hours (1500 impressions, which is less than 2x 1000)
          create(:billboard_event,
                 billboard: billboard,
                 category: "impression",
                 counts_for: 500,
                 created_at: now - 12.hours)
          create(:billboard_event,
                 billboard: billboard,
                 category: "impression",
                 counts_for: 1000,
                 created_at: now - 6.hours)

          # Create impressions older than 24 hours (should not be counted)
          create(:billboard_event,
                 billboard: billboard,
                 category: "impression",
                 counts_for: 2000,
                 created_at: now - 25.hours)
        end

        it "updates past 24 hours impressions and does not pause" do
          travel_to(now) do
            worker.perform

            organization.reload
            expect(organization.past_24_hours_promoted_billboard_impressions).to eq(1500)
            expect(organization.currently_paused_promotional_billboards).to be(false)
          end
        end

        it "caches empty list of paused organization IDs" do
          travel_to(now) do
            worker.perform

            paused_ids = described_class.paused_organization_ids
            expect(paused_ids).to be_empty
          end
        end
      end

      context "when impressions exceed 2x ideal daily" do
        before do
          # Create impressions that exceed 2x ideal (2500 impressions > 2 * 1000)
          create(:billboard_event,
                 billboard: billboard,
                 category: "impression",
                 counts_for: 1500,
                 created_at: now - 12.hours)
          create(:billboard_event,
                 billboard: billboard,
                 category: "impression",
                 counts_for: 1000,
                 created_at: now - 6.hours)
        end

        it "updates past 24 hours impressions and pauses promotional billboards" do
          travel_to(now) do
            worker.perform

            organization.reload
            expect(organization.past_24_hours_promoted_billboard_impressions).to eq(2500)
            expect(organization.currently_paused_promotional_billboards).to be(true)
          end
        end

        it "caches the paused organization ID" do
          travel_to(now) do
            worker.perform

            paused_ids = described_class.paused_organization_ids
            expect(paused_ids).to contain_exactly(organization.id)
          end
        end
      end

      context "when impressions exactly equal 2x ideal daily" do
        before do
          # Create impressions that exactly equal 2x ideal (2000 impressions = 2 * 1000)
          create(:billboard_event,
                 billboard: billboard,
                 category: "impression",
                 counts_for: 2000,
                 created_at: now - 12.hours)
        end

        it "does not pause (must be greater than 2x)" do
          travel_to(now) do
            worker.perform

            organization.reload
            expect(organization.past_24_hours_promoted_billboard_impressions).to eq(2000)
            expect(organization.currently_paused_promotional_billboards).to be(false)
          end
        end
      end

      context "when organization transitions from paused to unpaused" do
        before do
          organization.update_column(:currently_paused_promotional_billboards, true)
          Rails.cache.write(described_class::CACHE_KEY, [organization.id])

          # Create fewer impressions that don't exceed threshold
          create(:billboard_event,
                 billboard: billboard,
                 category: "impression",
                 counts_for: 1500,
                 created_at: now - 12.hours)
        end

        it "unpauses the organization" do
          travel_to(now) do
            worker.perform

            organization.reload
            expect(organization.currently_paused_promotional_billboards).to be(false)
          end
        end

        it "removes organization from cached paused list" do
          travel_to(now) do
            worker.perform

            paused_ids = described_class.paused_organization_ids
            expect(paused_ids).to be_empty
          end
        end
      end

      context "with multiple billboards for the same organization" do
        let(:billboard2) { create(:billboard, organization: organization) }

        before do
          create(:billboard_event,
                 billboard: billboard,
                 category: "impression",
                 counts_for: 800,
                 created_at: now - 12.hours)
          create(:billboard_event,
                 billboard: billboard2,
                 category: "impression",
                 counts_for: 700,
                 created_at: now - 6.hours)
        end

        it "sums impressions across all billboards" do
          travel_to(now) do
            worker.perform

            organization.reload
            expect(organization.past_24_hours_promoted_billboard_impressions).to eq(1500)
          end
        end
      end

      context "when only counting impression events" do
        before do
          # Create various event types, but only impressions should be counted
          create(:billboard_event,
                 billboard: billboard,
                 category: "impression",
                 counts_for: 500,
                 created_at: now - 12.hours)
          create(:billboard_event,
                 billboard: billboard,
                 category: "click",
                 counts_for: 1000,
                 created_at: now - 6.hours)
          create(:billboard_event,
                 billboard: billboard,
                 category: "conversion",
                 counts_for: 2000,
                 created_at: now - 3.hours)
        end

        it "only counts impression events" do
          travel_to(now) do
            worker.perform

            organization.reload
            expect(organization.past_24_hours_promoted_billboard_impressions).to eq(500)
          end
        end
      end
    end

    context "when organization has no tracking enabled" do
      let(:organization) do
        create(:organization,
               ideal_daily_promoted_billboard_impressions: 0,
               past_24_hours_promoted_billboard_impressions: 0,
               currently_paused_promotional_billboards: false)
      end

      let(:billboard) { create(:billboard, organization: organization) }

      before do
        create(:billboard_event,
               billboard: billboard,
               category: "impression",
               counts_for: 5000,
               created_at: now - 12.hours)
      end

      it "does not process the organization" do
        travel_to(now) do
          worker.perform

          organization.reload
          expect(organization.past_24_hours_promoted_billboard_impressions).to eq(0)
          expect(organization.currently_paused_promotional_billboards).to be(false)
        end
      end
    end

    context "with multiple organizations" do
      let(:org1) do
        create(:organization,
               ideal_daily_promoted_billboard_impressions: 1000,
               past_24_hours_promoted_billboard_impressions: 0,
               currently_paused_promotional_billboards: false)
      end

      let(:org2) do
        create(:organization,
               ideal_daily_promoted_billboard_impressions: 500,
               past_24_hours_promoted_billboard_impressions: 0,
               currently_paused_promotional_billboards: false)
      end

      let(:org3) do
        create(:organization,
               ideal_daily_promoted_billboard_impressions: 0)
      end

      let(:billboard1) { create(:billboard, organization: org1) }
      let(:billboard2) { create(:billboard, organization: org2) }
      let(:billboard3) { create(:billboard, organization: org3) }

      before do
        # Org1: 2500 impressions (exceeds 2x 1000 = 2000) - should be paused
        create(:billboard_event,
               billboard: billboard1,
               category: "impression",
               counts_for: 2500,
               created_at: now - 12.hours)

        # Org2: 800 impressions (exceeds 2x 500 = 1000) - should NOT be paused
        create(:billboard_event,
               billboard: billboard2,
               category: "impression",
               counts_for: 800,
               created_at: now - 6.hours)

        # Org3: 5000 impressions but tracking disabled - should be ignored
        create(:billboard_event,
               billboard: billboard3,
               category: "impression",
               counts_for: 5000,
               created_at: now - 3.hours)
      end

      it "processes only organizations with tracking enabled" do
        travel_to(now) do
          worker.perform

          org1.reload
          org2.reload
          org3.reload

          expect(org1.past_24_hours_promoted_billboard_impressions).to eq(2500)
          expect(org1.currently_paused_promotional_billboards).to be(true)

          expect(org2.past_24_hours_promoted_billboard_impressions).to eq(800)
          expect(org2.currently_paused_promotional_billboards).to be(false)

          expect(org3.past_24_hours_promoted_billboard_impressions).to eq(0)
          expect(org3.currently_paused_promotional_billboards).to be(false)
        end
      end

      it "caches only paused organization IDs" do
        travel_to(now) do
          worker.perform

          paused_ids = described_class.paused_organization_ids
          expect(paused_ids).to contain_exactly(org1.id)
        end
      end
    end

    context "when cache expires" do
      let(:organization) do
        create(:organization,
               ideal_daily_promoted_billboard_impressions: 1000,
               past_24_hours_promoted_billboard_impressions: 0,
               currently_paused_promotional_billboards: false)
      end

      let(:billboard) { create(:billboard, organization: organization) }

      before do
        create(:billboard_event,
               billboard: billboard,
               category: "impression",
               counts_for: 2500,
               created_at: now - 12.hours)
      end

      it "refreshes the cache with current paused organization IDs" do
        travel_to(now) do
          # Set old cache data
          Rails.cache.write(described_class::CACHE_KEY, [999], expires_in: 1.hour)

          worker.perform

          paused_ids = described_class.paused_organization_ids
          expect(paused_ids).to contain_exactly(organization.id)
        end
      end
    end
  end

  describe ".paused_organization_ids" do
    context "when cache is empty" do
      it "returns an empty array" do
        expect(described_class.paused_organization_ids).to eq([])
      end
    end

    context "when cache has paused organization IDs" do
      before do
        Rails.cache.write(described_class::CACHE_KEY, [1, 2, 3])
      end

      it "returns the cached organization IDs" do
        expect(described_class.paused_organization_ids).to eq([1, 2, 3])
      end
    end
  end
end

