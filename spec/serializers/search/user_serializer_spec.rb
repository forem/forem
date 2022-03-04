require "rails_helper"

RSpec.describe Search::UserSerializer do
  let(:user) { create(:user) }

  it "serializes a user" do
    data_hash = described_class.new(user).serializable_hash.dig(:data, :attributes)
    expect(data_hash.keys).to include(:id, :name, :path, :username, :roles)
  end
end
