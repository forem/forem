require "rails_helper"

RSpec.describe Badges::AwardCommunityWellness, type: :service do
  # Create one user per reward streak to test against
  let(:reward_weeks) { Badges::AwardCommunityWellness::REWARD_STREAK_WEEKS }
  let!(:users) { create_list(:user, reward_weeks.count) }
  # Using a list of articles to sample from helps to avoid creating new articles
  # for each comment to be created by `create_comment_time_ago`
  let!(:articles) { create_list(:article, 4) }

  before do
    reward_weeks.each do |week|
      create(
        :badge,
        title: "#{week} Week Community Wellness Streak",
        slug: "#{week}-week-community-wellness-streak",
      )
    end

    users.each_with_index do |_user, index|
      # Create 2 comments per-week to be tested, i.e. week 8 would create 2
      # comments on each of the 8 weeks (calculated on days_ago per week)
      reward_weeks[index].times do |week|
        days_ago = (8 + (week * 7)).days.ago
        create_comment_time_ago(users[index].id, days_ago, commentable: articles.sample)
        create_comment_time_ago(users[index].id, days_ago, commentable: articles.sample)
      end
    end
  end

  context "when user meets a new streak level" do
    # Test against each week that has a reward associated to it. All mock users
    # are expected to receive a badge in this spec (one per reward_weeks)
    it "awards a badge to each user with a streak of non-flagged comments" do
      expect do
        described_class.call
        users.each_with_index do |user, index|
          # Each user must be tested against it's corresponding streak
          expected_user_streak = reward_weeks[index]
          badge_slug = "#{expected_user_streak}-week-community-wellness-streak"
          expect(user.reload.badges.last.slug).to eq(badge_slug)
        end
      end.to change(BadgeAchievement, :count).by(users.count)
    end
  end
end
