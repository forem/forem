require "rails_helper"

RSpec.describe BillboardCampaign do
  let(:campaign) { described_class.create!(name: "Season launch") }

  it { is_expected.to validate_presence_of(:name) }

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
