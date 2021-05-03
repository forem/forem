require "rails_helper"

RSpec.describe Listing, type: :model do
  let(:user) { create(:user) }
  let(:organization) { create(:organization) }
  let(:listing) { create(:listing, user: user) }

  # TODO: Remove setting of default parser from a model's callback
  # This may apply default parser on area that should not use it.
  after { ActsAsTaggableOn.default_parser = ActsAsTaggableOn::DefaultParser }

  it { is_expected.to validate_presence_of(:title) }
  it { is_expected.to validate_presence_of(:body_markdown) }
  it { is_expected.to have_many(:credits) }

  describe "valid associations" do
    it "is not valid w/o user and org" do
      cl = build(:listing, user_id: nil, organization_id: nil)
      expect(cl).not_to be_valid
      expect(cl.errors[:user_id]).to be_truthy
      expect(cl.errors[:organization_id]).to be_truthy
    end

    it "is valid with user_id and without organization_id" do
      cl = build(:listing, user_id: user.id, organization_id: nil)
      expect(cl).to be_valid
    end

    it "is valid with user_id and organization_id" do
      cl = build(:listing, user_id: user.id, organization_id: organization.id)
      expect(cl).to be_valid
    end
  end

  describe "body html" do
    it "converts markdown to html" do
      expect(listing.processed_html).to include("<p>")
    end

    it "accepts 8 tags or less" do
      listing.tag_list = "a, b, c, d, e, f, g"
      expect(listing.valid?).to eq(true)
    end

    it "cleans images" do
      listing.body_markdown = "hello <img src='/dssdsdsd.jpg'> hey hey hey"
      listing.save
      expect(listing.processed_html).not_to include("<img")
    end

    it "doesn't accept more than 8 tags" do
      listing.tag_list = "a, b, c, d, e, f, g, h, z, t, s, p"
      expect(listing.valid?).to eq(false)
      expect(listing.errors[:tag_list]).to be_truthy
    end

    it "parses away tag spaces" do
      listing.tag_list = "the best, tag list"
      listing.save
      expect(listing.tag_list).to eq(%w[thebest taglist])
    end
  end

  describe "credits" do
    it "does not destroy associated credits if destroyed" do
      credit = create(:credit)
      listing.credits << credit
      listing.save!

      expect { listing.destroy }.not_to change(Credit, :count)
      expect(credit.reload.purchase).to be_nil
    end
  end
end
