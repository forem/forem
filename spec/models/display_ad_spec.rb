require "rails_helper"

RSpec.describe DisplayAd, type: :model do
  let(:organization) { create(:organization) }
  let(:display_ad) { create(:display_ad, organization_id: organization.id) }

  describe "validations" do
    describe "builtin validations" do
      subject { display_ad }

      it { is_expected.to belong_to(:organization) }
      it { is_expected.to have_many(:display_ad_events).dependent(:destroy) }

      it { is_expected.to validate_presence_of(:organization_id) }
      it { is_expected.to validate_presence_of(:placement_area) }
      it { is_expected.to validate_presence_of(:body_markdown) }
    end

    it "allows sidebar_right" do
      display_ad.placement_area = "sidebar_right"
      expect(display_ad).to be_valid
    end

    it "allows sidebar_left" do
      display_ad.placement_area = "sidebar_left"
      expect(display_ad).to be_valid
    end

    it "disallows unacceptable placement_area" do
      display_ad.placement_area = "tsdsdsdds"
      expect(display_ad).not_to be_valid
    end

    it "returns human readable name" do
      display_ad.placement_area = "sidebar_left_2"
      expect(display_ad.human_readable_placement_area).to eq("Sidebar Left (Second Position)")
    end
  end

  context "when callbacks are triggered before save" do
    it "generates #processed_html from #body_markdown" do
      expect(display_ad.processed_html).to start_with("<p>Hello <em>hey</em> Hey hey")
    end

    it "does not render disallowed tags" do
      display_ad.update(body_markdown: "<style>body { color: black}</style> Hey hey")
      expect(display_ad.processed_html).to eq("<p>body { color: black} Hey hey</p>")
    end

    it "does not render disallowed attributes" do
      display_ad.update(body_markdown: "<p style='margin-top:100px'>Hello <em>hey</em> Hey hey</p>")
      expect(display_ad.processed_html).to start_with("<p>Hello <em>hey</em> Hey hey</p>")
    end
  end

  describe ".for_display" do
    let!(:display_ad) { create(:display_ad, organization_id: organization.id) }

    it "does not return unpublished ads" do
      display_ad.update!(published: false, approved: true)
      expect(described_class.for_display(display_ad.placement_area)).to be_nil
    end

    it "does not return unapproved ads" do
      display_ad.update!(published: true, approved: false)
      expect(described_class.for_display(display_ad.placement_area)).to be_nil
    end

    it "returns published and approved ads" do
      display_ad.update!(published: true, approved: true)
      expect(described_class.for_display(display_ad.placement_area)).to eq(display_ad)
    end
  end
end
