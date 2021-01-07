require "rails_helper"

RSpec.describe Badges::AwardFabFive, type: :service do
  it "awards fab five badge to users" do
    create(:badge, title: "Fab 5")
    user = create(:user)
    other_user = create(:user)

    expect do
      described_class.call([user.username, other_user.username])
    end.to change(BadgeAchievement, :count).by(2)
  end
end
