require "rails_helper"

RSpec.describe Search::OrganizationSerializer do
  let(:organization) { create(:organization) }

  it "serializes a organization" do
    data_hash = described_class.new(organization).serializable_hash.dig(:data, :attributes)
    expect(data_hash.keys).to include(:id, :name, :summary, :profile_image, :twitter_username, :nav_image, :slug)
    expect(data_hash[:id]).to eq(organization.id)
    expect(data_hash[:name]).to eq(organization.name)
    expect(data_hash[:profile_image]).to eq(organization.profile_image)
  end
end
