require "rails_helper"

RSpec.describe Users::UsernameGenerator, type: :service do
  let(:user) { create(:user) }

  it "returns generated username if provider username is present" do
    user.github_username = "github123"
    expect(described_class.call(user)).to eq("github123")
  end

  it "returns random username if provider username is not present" do
    expect(described_class.call(user)).to be_present
  end

  it "returns random username if provider username already exists" do
    create(:user, username: "github123")
    user.username = ""
    user.github_username = "github123"
    expect(described_class.call(user)).not_to eq("github123")
  end

  it "returns nil if all generating methods are exhausted" do
    user.username = "taken_username"
    user.save
    new_user = build(:user, username: nil)
    username_generator = described_class.new(new_user)
    allow(username_generator).to receive(:from_auth_providers).and_return(nil)
    allow(username_generator).to receive(:random_letters).and_return("taken_username")
    expect(username_generator.call).to be_nil
  end
end
