require "rails_helper"

RSpec.describe BadgeAchievement, type: :model do
  let(:user) { create(:user) }
  let(:badge) { create(:badge) }

  describe "validations" do
    subject { BadgeAchievement.create(user_id: user.id, badge_id: badge.id) }

    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:badge) }
    it { is_expected.to belong_to(:rewarder).class_name("User") }
  end

  it "allow duplicate badges" do
    BadgeAchievement.create(user_id: user.id, badge_id: badge.id, rewarder_id: create(:user).id)
    expect do
      BadgeAchievement.create!(user_id: user.id, badge_id: badge.id, rewarder_id: create(:user).id)
    end.not_to raise_error
  end
end
