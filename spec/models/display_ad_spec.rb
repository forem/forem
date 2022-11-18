require "rails_helper"

RSpec.describe DisplayAd, type: :model do
  let(:organization) { create(:organization) }
  let(:display_ad) { create(:display_ad, organization_id: organization.id) }

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

  describe "after_create callbacks" do
    it "generates a name when one does not exist" do
      display_ad = create(:display_ad, name: nil)
      display_ad_with_name = create(:display_ad, name: "Test")

      expect(display_ad.name).to eq("Display Ad #{display_ad.id}")
      expect(display_ad_with_name.name).to eq("Test")
    end
  end

  describe ".for_display" do
    context "when updating the published and approved values" do
      let!(:display_ad) { create(:display_ad, organization_id: organization.id) }

      it "does not return unpublished ads" do
        display_ad.update!(published: false, approved: true)
        expect(described_class.for_display(display_ad.placement_area, false)).to be_nil
      end

      it "does not return unapproved ads" do
        display_ad.update!(published: true, approved: false)
        expect(described_class.for_display(display_ad.placement_area, false)).to be_nil
      end

      it "returns published and approved ads" do
        display_ad.update!(published: true, approved: true)
        expect(described_class.for_display(display_ad.placement_area, false)).to eq(display_ad)
      end
    end

    context "when considering article_tags" do
      it "will show the display ads that contain tags that match any of the article tags" do
        display_ad = create(:display_ad, organization_id: organization.id,
                                         placement_area: "post_comments",
                                         published: true,
                                         approved: true,
                                         cached_tag_list: "linux, git, go")

        create(:display_ad, organization_id: organization.id,
                            placement_area: "post_comments",
                            published: true,
                            approved: true,
                            cached_tag_list: "career")

        article_tags = %w[linux productivity]
        expect(described_class.for_display("post_comments", false, article_tags)).to eq(display_ad)
      end

      it "will show display ads that have no tags set" do
        display_ad = create(:display_ad, organization_id: organization.id,
                                         placement_area: "post_comments",
                                         published: true,
                                         approved: true,
                                         cached_tag_list: "")

        create(:display_ad, organization_id: organization.id,
                            placement_area: "post_comments",
                            published: true,
                            approved: true,
                            cached_tag_list: "career")

        article_tags = %w[productivity java]
        expect(described_class.for_display("post_comments", false, article_tags)).to eq(display_ad)
      end

      it "will show no display ads if the available display ads have no tags set or do not contain matching tags" do
        create(:display_ad, organization_id: organization.id,
                            placement_area: "post_comments",
                            published: true,
                            approved: true,
                            cached_tag_list: "productivity")
        article_tags = %w[javascript]
        expect(described_class.for_display("post_comments", false, article_tags)).to be_nil
      end

      it "will show display ads with no tags set if there are no article tags" do
        create(:display_ad, organization_id: organization.id,
                            placement_area: "post_comments",
                            published: true,
                            approved: true,
                            cached_tag_list: "productivity")

        display_ad_without_tags = create(:display_ad, organization_id: organization.id,
                                                      placement_area: "post_comments",
                                                      published: true,
                                                      approved: true,
                                                      cached_tag_list: "")

        expect(described_class.for_display("post_comments", false)).to eq(display_ad_without_tags)
      end
    end

    context "when display_to is set to 'logged_in' or 'logged_out'" do
      let!(:display_ad2) do
        create(:display_ad, organization_id: organization.id, published: true, approved: true, display_to: "logged_in")
      end
      let!(:display_ad3) do
        create(:display_ad, organization_id: organization.id, published: true, approved: true, display_to: "logged_out")
      end

      it "shows ads that have a display_to of 'logged_in' if a user is signed in" do
        expect(described_class.for_display(display_ad2.placement_area, true)).to eq(display_ad2)
      end

      it "shows ads that have a display_to of 'logged_out' if a user is signed in" do
        expect(described_class.for_display(display_ad3.placement_area, false)).to eq(display_ad3)
      end
    end

    context "when display_to is set to 'all'" do
      let!(:display_ad) do
        create(:display_ad, organization_id: organization.id, published: true, approved: true, display_to: "all")
      end

      it "shows ads that have a display_to of 'all' if a user is signed in" do
        expect(described_class.for_display(display_ad.placement_area, true)).to eq(display_ad)
      end

      it "shows ads that have a display_to of 'all' if a user is not signed in" do
        expect(described_class.for_display(display_ad.placement_area, false)).to eq(display_ad)
      end
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
