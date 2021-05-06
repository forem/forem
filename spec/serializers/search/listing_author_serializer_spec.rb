require "rails_helper"

RSpec.describe Search::ListingAuthorSerializer do
  let(:user) { create(:user) }

  it "serializes a ListingAuthor" do
    data_hash = described_class.new(user).serializable_hash.dig(:data, :attributes)
    expect(data_hash.keys).to include(:username, :name, :profile_image_90)
    expect(data_hash[:username]).to eq(user.username)
    expect(data_hash[:name]).to eq(user.name)
    expect(data_hash[:profile_image_90]).to eq(user.profile_image_90)
  end
end
