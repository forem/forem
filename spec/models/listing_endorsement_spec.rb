require "rails_helper"

RSpec.describe ListingEndorsement, type: :model do
  let(:user) { create(:user) }
  let(:listing) { create(:listing, user: user) }

  it { is_expected.to validate_presence_of(:content) }
  it { is_expected.to validate_presence_of(:approved) }
  it { is_expected.to belong_to(:listings) }

  describe "valid associations" do
    it "is not valid w/o user" do
      cl = build(:listing, user_id: nil)
      expect(cl).not_to be_valid
      expect(cl.errors[:user_id]).to be_truthy
    end

    it "is not valid w/o listing" do
      cl = build(classified_listing_id: nil, user_id: user.id)
      expect(cl).not_to be_valid
    end

    it "is valid with listing and user" do
      cl = build(:listing, user_id: user.id)
      expect(cl).to be_valid
    end
  end
end
