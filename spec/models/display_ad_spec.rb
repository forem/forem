require "rails_helper"

RSpec.describe DisplayAd, type: :model do
  let(:display_ad) { create(:display_ad, organization_id: organization.id) }
  let(:organization) { create(:organization) }

  it { is_expected.to validate_presence_of(:organization_id) }
  it { is_expected.to validate_presence_of(:placement_area) }
  it { is_expected.to validate_presence_of(:body_markdown) }

  it "generates processed_html before save" do
    expect(display_ad.processed_html).to eq("Hello <em>hey</em> Hey hey")
  end
  it "only disallows unacceptable placement_area" do
    display_ad.placement_area = "tsdsdsdds"
    expect(display_ad).not_to be_valid
  end
  it "only allows acceptable placement_area" do
    display_ad.placement_area = "sidebar"
    expect(display_ad).to be_valid
  end
end
