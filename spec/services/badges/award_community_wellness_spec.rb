require "rails_helper"

RSpec.describe Badges::AwardCommunityWellness, type: :service do
  let(:user) { create(:user) }

  before do
    create(:badge, title: "4 Week Community Wellness Streak", slug: "4-week-wellness-streak")
  end

  it "awards badge to users with a streak of non-flagged comments" do
    p "TODO :)"
  end

  # it "does not award the badge to not qualified users" do
  #   expect do
  #     described_class.call(weeks: 4)
  #   end.not_to change { user.reload.badges.size }
  # end
end
