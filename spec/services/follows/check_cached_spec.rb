require "rails_helper"

RSpec.describe Follows::CheckCached, type: :service do
  let(:user) { create(:user) }

  it "checks if following a thing and returns true if they are" do
    user2 = create(:user)
    user.follow(user2)
    expect(described_class.call(user, "User", user2.id)).to eq(true)
  end

  it "checks if following a thing and returns false if they are not" do
    user2 = create(:user)
    expect(described_class.call(user, "User", user2.id)).to eq(false)
  end
end
