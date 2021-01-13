require "rails_helper"

RSpec.describe Badges::AwardContributor, type: :service do
  it "awards contributor badge to users" do
    create(:badge, title: "DEV Contributor")
    user = create(:user)
    other_user = create(:user)

    expect do
      described_class.call([user.username, other_user.username])
    end.to change(BadgeAchievement, :count).by(2)
  end
end
