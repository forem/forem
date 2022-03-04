require "rails_helper"

RSpec.describe Badges::AwardTopSeven, type: :service do
  it "awards top seven badge to users" do
    create(:badge, title: "Top 7")
    user = create(:user)
    other_user = create(:user)

    expect do
      described_class.call([user.username, other_user.username])
    end.to change(BadgeAchievement, :count).by(2)
  end
end
