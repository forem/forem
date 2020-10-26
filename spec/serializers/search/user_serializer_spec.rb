require "rails_helper"

RSpec.describe Search::UserSerializer do
  let(:user) { create(:user) }

  it "serializes a user" do
    data_hash = described_class.new(user).serializable_hash.dig(:data, :attributes)
    expect(data_hash.keys).to include(:id, :name, :path, :username, :roles)
  end

  it "creates valid json for Elasticsearch", elasticsearch: "User" do
    data_hash = described_class.new(user).serializable_hash.dig(:data, :attributes)
    result = User::SEARCH_CLASS.index(user.id, data_hash)
    expect(result["result"]).to eq("created")
  end

  it "indexes profile fields as a nested field", elasticsearch: "User", aggregate_failures: true do
    data_hash = described_class.new(user).serializable_hash.dig(:data, :attributes)
    result = User::SEARCH_CLASS.index(user.id, data_hash)
    expect(result["result"]).to eq("created")
    indexed_profile_fields = user.reload.elasticsearch_doc.dig("_source", "profile_fields")
    expect(indexed_profile_fields).to be_an_instance_of(Array)
  end

  it "indexes custom profile fields as a nested field", elasticsearch: "User", aggregate_failures: true do
    data_hash = described_class.new(user).serializable_hash.dig(:data, :attributes)
    result = User::SEARCH_CLASS.index(user.id, data_hash)
    expect(result["result"]).to eq("created")
    indexed_custom_fields = user.reload.elasticsearch_doc.dig("_source", "custom_profile_fields")
    expect(indexed_custom_fields).to be_an_instance_of(Array)
  end
end
