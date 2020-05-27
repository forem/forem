require "rails_helper"

RSpec.describe DisplayAd, type: :model do
  let_it_be(:organization) { create(:organization) }
  let_it_be(:display_ad) { create(:display_ad, organization_id: organization.id) }

  it { is_expected.to validate_presence_of(:organization_id) }
  it { is_expected.to validate_presence_of(:placement_area) }
  it { is_expected.to validate_presence_of(:body_markdown) }

  describe "validations" do
    xit "allows sidebar_right" do
      display_ad.placement_area = "sidebar_right"
      expect(display_ad).to be_valid
    end

    xit "allows sidebar_left" do
      display_ad.placement_area = "sidebar_left"
      expect(display_ad).to be_valid
    end

    xit "disallows unacceptable placement_area" do
      display_ad.placement_area = "tsdsdsdds"
      expect(display_ad).not_to be_valid
    end
  end

  context "when callbacks are triggered before save" do
    xit "generates #processed_html from #body_markdown" do
      expect(display_ad.processed_html).to eq("<p>Hello <em>hey</em> Hey hey</p>")
    end
  end

  describe ".for_display" do
    let!(:display_ad) { create(:display_ad, organization_id: organization.id) }

    xit "does not return unpublished ads" do
      display_ad.update!(published: false, approved: true)
      expect(described_class.for_display(display_ad.placement_area)).to be_nil
    end

    xit "does not return unapproved ads" do
      display_ad.update!(published: true, approved: false)
      expect(described_class.for_display(display_ad.placement_area)).to be_nil
    end

    xit "returns published and approved ads" do
      display_ad.update!(published: true, approved: true)
      expect(described_class.for_display(display_ad.placement_area)).to eq(display_ad)
    end
  end
end
