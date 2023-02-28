require "rails_helper"

RSpec.describe DisplayAd do
  let(:organization) { build(:organization) }
  let(:display_ad) { build(:display_ad, organization: nil) }

  it_behaves_like "Taggable"

  describe "validations" do
    describe "builtin validations" do
      subject { display_ad }

      it { is_expected.to belong_to(:organization).optional }
      it { is_expected.to have_many(:display_ad_events).dependent(:destroy) }

      it { is_expected.to validate_presence_of(:placement_area) }
      it { is_expected.to validate_presence_of(:body_markdown) }
      it { is_expected.to have_many(:tags) }
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

    it "allows creator_id to be set" do
      display_ad.creator = build(:user)
      expect(display_ad).to be_valid
    end

    it "does not require creator to be valid" do
      display_ad.creator = nil
      expect(display_ad).to be_valid
    end

    it "requires organization_id for community-type ads" do
      expect(display_ad).to be_valid

      display_ad.type_of = "community"
      expect(display_ad).not_to be_valid
      expect(display_ad.errors[:organization]).not_to be_blank

      display_ad.organization = organization
      expect(display_ad).to be_valid
      expect(display_ad.errors[:organization]).to be_blank
    end
  end

  context "when callbacks are triggered before save" do
    before { display_ad.save! }

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

  describe "after_create callbacks" do
    it "generates a name when one does not exist" do
      display_ad = create(:display_ad, name: nil)
      display_ad_with_name = create(:display_ad, name: "Test")

      expect(display_ad.name).to eq("Display Ad #{display_ad.id}")
      expect(display_ad_with_name.name).to eq("Test")
    end
  end

  describe ".search_ads" do
    let!(:ad) { create(:display_ad, name: "This is an Ad", body_markdown: "Ad Body", placement_area: "post_comments") }

    it "finds via name" do
      expect(described_class.search_ads("this").ids).to contain_exactly(ad.id)
    end

    it "finds via body" do
      expect(described_class.search_ads("body").ids).to contain_exactly(ad.id)
    end

    it "finds via placement_area" do
      expect(described_class.search_ads("comment").ids).to contain_exactly(ad.id)
    end

    it "finds just one result via multiple criteria" do
      expect(described_class.search_ads("ad").ids).to contain_exactly(ad.id)
    end

    it "returns empty when no match" do
      expect(described_class.search_ads("foo")).to eq([])
    end
  end

  describe ".validate_tag" do
    it "rejects more than 10 tags" do
      eleven_tags = "one, two, three, four, five, six, seven, eight, nine, ten, eleven"
      expect(build(:display_ad,
                   name: "This is an Ad",
                   body_markdown: "Ad Body",
                   placement_area: "post_comments",
                   tag_list: eleven_tags).valid?).to be(false)
    end

    it "rejects tags with length > 30" do
      tags = "'testing tag length with more than 30 chars', tag"
      expect(build(:display_ad,
                   name: "This is an Ad",
                   body_markdown: "Ad Body",
                   placement_area: "post_comments",
                   tag_list: tags).valid?).to be(false)
    end

    it "rejects tag with non-alphanumerics" do
      expect do
        build(:display_ad,
              name: "This is an Ad",
              body_markdown: "Ad Body",
              placement_area: "post_comments",
              tag_list: "c++").validate!
      end.to raise_error(ActiveRecord::RecordInvalid)
    end

    it "always downcase tags" do
      tags = "UPPERCASE, CAPITALIZE"
      display_ad = create(:display_ad,
                          name: "This is an Ad",
                          body_markdown: "Ad Body",
                          placement_area: "post_comments",
                          tag_list: tags)
      expect(display_ad.tag_list).to eq(tags.downcase.split(", "))
    end
  end
end
