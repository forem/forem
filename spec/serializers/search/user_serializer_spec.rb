require "rails_helper"

RSpec.describe Search::UserSerializer do
  let(:user) { create(:user) }

  it "serializes a user" do
    data_hash = described_class.new(user).serializable_hash.dig(:data, :attributes)
    expect(data_hash.keys).to include(:id, :name, :path, :username, :roles)
  end

  it "creates valid json for Elasticsearch", elasticsearch: true do
    data_hash = described_class.new(user).serializable_hash.dig(:data, :attributes)
    result = User::SEARCH_CLASS.index(user.id, data_hash)
    expect(result["result"]).to eq("created")
  end
end
