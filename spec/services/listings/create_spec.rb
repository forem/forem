require "rails_helper"

RSpec.describe Listings::Create, type: :service do
  let(:user) { create(:user) }
  let(:listing) { build(:listing, user: user) }

  it "is successful when the purchaser has enough credits" do
    create(:credit, user: user)
    create_result = described_class.call(listing, purchaser: user, cost: 1)
    expect(create_result.success?).to be true
  end

  it "fails if the purchaser doesn't have enough credits" do
    create_result = described_class.call(listing, purchaser: user, cost: 1)
    expect(create_result.success?).to be false
  end
end
