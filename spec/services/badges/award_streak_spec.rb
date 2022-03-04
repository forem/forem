require "rails_helper"

RSpec.describe Badges::AwardStreak, type: :service do
  let(:user) { create(:user) }

  before do
    create(:badge, title: "4 Week Streak", slug: "4-week-streak")
    create(:article, user: user, published: true, published_at: 26.days.ago)
    create(:article, user: user, published: true, published_at: 19.days.ago)
    create(:article, user: user, published: true, published_at: 5.days.ago)
  end

  it "awards badge to users with four straight weeks of articles" do
    create(:article, user: user, published: true, published_at: 12.days.ago)
    expect do
      described_class.call(weeks: 4)
    end.to change { user.reload.badges.size }.by(1)
  end

  it "does not award the badge to not qualified users" do
    expect do
      described_class.call(weeks: 4)
    end.not_to change { user.reload.badges.size }
  end
end
