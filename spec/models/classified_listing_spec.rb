require 'rails_helper'

RSpec.describe ClassifiedListing, type: :model do
  it { is_expected.to validate_presence_of(:title) }
  it { is_expected.to validate_presence_of(:body_markdown) }

  let(:user) { create(:user)}
  let(:classified_listing) { create(:classified_listing, user_id: user.id)}

  describe "body html" do
    it "converts markdown to html" do
      expect(classified_listing.processed_html).to include("<p>")
    end

    it "accepts 8 tags or less" do
      classified_listing.tag_list = "a, b, c, d, e, f, g"
      expect(classified_listing.valid?).to eq(true)
    end
    it "accepts 8 tags or less" do
      classified_listing.tag_list = "a, b, c, d, e, f, g, h, z, t, s, p"
      expect(classified_listing.valid?).to eq(false)
    end
    it "parses away spaces" do
      classified_listing.tag_list = "the best, tag list"
      classified_listing.save
      expect(classified_listing.tag_list).to eq(%w[thebest taglist])
    end
  end
end
