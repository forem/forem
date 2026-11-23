require "rails_helper"

RSpec.describe BillboardCampaign do
  let(:campaign) { described_class.create!(name: "Season launch") }

  it { is_expected.to validate_presence_of(:name) }

  it do
    expect(campaign).to validate_numericality_of(:ideal_daily_impressions)
      .only_integer.is_greater_than_or_equal_to(0).is_less_than_or_equal_to(described_class::MAX_CAP)
  end

  it do
    expect(campaign).to validate_numericality_of(:delivery_throttle_rate)
      .is_greater_than_or_equal_to(0.0).is_less_than_or_equal_to(1.0)
  end

  describe ".with_ideal_daily_impressions" do
    it "returns only campaigns with positive ideal_daily_impressions" do
      paced = described_class.create!(name: "Paced", ideal_daily_impressions: 5_000)
      described_class.create!(name: "Unpaced", ideal_daily_impressions: 0)

      expect(described_class.with_ideal_daily_impressions).to eq([paced])
    end
  end

  describe "resetting throttle state when ideal_daily_impressions is disabled" do
    before do
      allow(Rails).to receive(:cache).and_return(ActiveSupport::Cache::MemoryStore.new)
      Rails.cache.clear
      MemoryFirstCache.clear
    end

    it "resets delivery_throttle_rate to 1.0 and removes the campaign from the throttle cache" do
      paced = described_class.create!(name: "Paced", ideal_daily_impressions: 5_000, delivery_throttle_rate: 0.25)
      Billboards::CampaignPacing.write_throttled_campaign_rates(paced.id => 0.25)

      paced.update!(ideal_daily_impressions: 0)

      expect(paced.reload.delivery_throttle_rate).to eq(1.0)
      expect(Billboards::CampaignPacing.throttled_campaign_rates).to eq({})
    end

    it "removes the campaign from the throttle cache when destroyed" do
      paced = described_class.create!(name: "Paced", ideal_daily_impressions: 5_000, delivery_throttle_rate: 0.25)
      Billboards::CampaignPacing.write_throttled_campaign_rates(paced.id => 0.25)

      paced.destroy!

      expect(Billboards::CampaignPacing.throttled_campaign_rates).to eq({})
    end
  end

  describe "#expired?" do
    it "is false without an end date" do
      expect(campaign).not_to be_expired
    end

    it "is true once the end date has passed" do
      campaign.expires_at = 1.minute.ago
      expect(campaign).to be_expired
    end
  end

  describe "#over_cap?" do
    it "is false when no cap is set" do
      create(:billboard, billboard_campaign: campaign).update_column(:impressions_count, 1_000)
      expect(campaign).not_to be_over_cap
    end

    it "sums impressions across the campaign's billboards" do
      campaign.update!(max_impressions_count: 100)
      create(:billboard, billboard_campaign: campaign).update_column(:impressions_count, 60)
      expect(campaign).not_to be_over_cap

      create(:billboard, billboard_campaign: campaign).update_column(:impressions_count, 40)
      expect(campaign).to be_over_cap
    end

    it "counts a billboard that is joining the campaign exactly once" do
      campaign.update!(max_impressions_count: 100)
      member = create(:billboard, billboard_campaign: campaign)
      member.update_column(:impressions_count, 60)
      joining = build(:billboard, impressions_count: 40)

      expect(campaign.over_cap?(joining)).to be(true)
      expect(campaign.over_cap?(member.reload)).to be(false)
    end

    it "sums clicks across the campaign's billboards" do
      campaign.update!(max_clicks_count: 3)
      create(:billboard, billboard_campaign: campaign).update_column(:clicks_count, 3)
      expect(campaign).to be_over_cap
    end
  end

  it "detaches its billboards when destroyed" do
    billboard = create(:billboard, billboard_campaign: campaign)
    campaign.destroy!
    expect(billboard.reload.billboard_campaign_id).to be_nil
  end
end
