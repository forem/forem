require 'rails_helper'

RSpec.describe FollowChecker do
  let(:user) { create(:user) }
  it "checks if following a thing and returns true if they are" do
    user_2 = create(:user)
    user.follow(user_2)
    expect(described_class.new(user, "User", user_2.id).cached_follow_check).to eq(true)
  end

  it "checks if following a thing and returns false if they are not" do
    user_2 = create(:user)
    expect(described_class.new(user, "User", user_2.id).cached_follow_check).to eq(false)
  end
end
