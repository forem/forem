require "rails_helper"

RSpec.describe Follow, type: :model do
  let(:user) { create(:user) }
  let(:user_2) { create(:user) }

  it "follows user" do
    user.follow(user_2)
    expect(user.following?(user_2)).to eq(true)
  end
end
