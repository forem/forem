require "rails_helper"

RSpec.describe Listing do
  let(:user) { create(:user) }
  let(:organization) { create(:organization) }
  let(:listing) { create(:listing, user: user) }

  # TODO: Remove setting of default parser from a model's callback
  # This may apply default parser on area that should not use it.
  after { ActsAsTaggableOn.default_parser = ActsAsTaggableOn::DefaultParser }

<<<<<<< HEAD
  it { is_expected.to validate_presence_of(:title) }
  it { is_expected.to validate_presence_of(:body_markdown) }
=======
  it { is_expected.to have_many(:credits) }
>>>>>>> 67884c1f6 (Remove unused validations from Listing model)


  describe "body html" do
    it "converts markdown to html" do
      expect(listing.processed_html).to include("<p>")
    end

    it "accepts 8 tags or less" do
      listing.tag_list = "a, b, c, d, e, f, g"
      expect(listing.valid?).to be(true)
    end

    it "parses away tag spaces" do
      listing.tag_list = "the best, tag list"
      listing.save
      expect(listing.tag_list).to eq(%w[thebest taglist])
    end
  end
end
