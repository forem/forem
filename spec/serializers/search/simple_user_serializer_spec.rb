require "rails_helper"

RSpec.describe Search::SimpleUserSerializer do
  let(:user) { create(:user) }

  it "serializes a User" do
    data_hash = described_class.new(user).serializable_hash.dig(:data, :attributes)
    expect(data_hash.keys).to include(:class_name, :id, :title, :user)
  end

  it "has the correct class_name" do
    class_name = described_class.new(user).serializable_hash.dig(:data, :attributes, :class_name)
    expect(class_name).to eq("User")
  end

  it "serializers the user key" do
    user_hash = described_class.new(user).serializable_hash.dig(:data, :attributes, :user)
    expect(user_hash.keys).to include(:username, :name, :profile_image_90)
    expect(user_hash[:username]).to eq(user.username)
    expect(user_hash[:profile_image_90]).to eq(user.profile_image_90)

    # currently the frontend expects this to be the username, despite the attribute name
    expect(user_hash[:name]).to eq(user.username)
  end
end
