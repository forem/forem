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
  it "allows sidebar_right" do
    display_ad.placement_area = "sidebar_right"
    expect(display_ad).to be_valid
  end
  it "allows sidebar_left" do
    display_ad.placement_area = "sidebar_left"
    expect(display_ad).to be_valid
  end

  it "displays published and approved posts" do
    create(:display_ad, organization_id: organization.id, published: true, approved: true)
    create(:display_ad, organization_id: organization.id, published: true, approved: true)
    create(:display_ad, organization_id: organization.id, published: false, approved: true)
    create(:display_ad, organization_id: organization.id, published: true, approved: false)
    expect(described_class.for_display(described_class.last.placement_area).published).to eq(true)
    expect(described_class.for_display(described_class.last.placement_area).approved).to eq(true)
  end
end
