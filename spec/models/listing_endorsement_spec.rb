require "rails_helper"

RSpec.describe ListingEndorsement, type: :model do
  let(:user) { create(:user) }
  let(:listing) { create(:listing, user: user) }
  let(:listing_endorsement) { create(:listing_endorsement, listing: listing, user: user) }

  it { is_expected.to validate_presence_of(:content) }
  it { is_expected.to belong_to(:listing) }
  it { is_expected.to belong_to(:user) }

  describe "valid associations" do
    it "is not valid w/o user" do
      cl = build(:listing_endorsement, user_id: nil)
      expect(cl).not_to be_valid
      expect(cl.errors[:user_id]).to be_truthy
    end

    it "is not valid w/o listing" do
      cl = build(:listing_endorsement, classified_listing_id: nil, user_id: user.id)
      expect(cl).not_to be_valid
    end

    it "is valid with listing and user" do
      cl = build(:listing_endorsement, classified_listing_id: listing.id, user_id: user.id)
      expect(cl).to be_valid
    end
  end
end
