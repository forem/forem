require "rails_helper"

RSpec.describe ClassifiedListing, type: :model do
  let(:classified_listing) { create(:classified_listing, user_id: user.id) }
  let(:user) { create(:user) }

  it { is_expected.to validate_presence_of(:title) }
  it { is_expected.to validate_presence_of(:body_markdown) }

  describe "body html" do
    it "converts markdown to html" do
      expect(classified_listing.processed_html).to include("<p>")
    end

    it "accepts 8 tags or less" do
      classified_listing.tag_list = "a, b, c, d, e, f, g"
      expect(classified_listing.valid?).to eq(true)
    end

    it "doesn't accept more than 8 tags" do
      classified_listing.tag_list = "a, b, c, d, e, f, g, h, z, t, s, p"
      expect(classified_listing.valid?).to eq(false)
      expect(classified_listing.errors[:tag_list]).to be_truthy
    end

    it "parses away spaces" do
      classified_listing.tag_list = "the best, tag list"
      classified_listing.save
      expect(classified_listing.tag_list).to eq(%w[thebest taglist])
    end
  end
end
