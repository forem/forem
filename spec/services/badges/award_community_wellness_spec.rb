require "rails_helper"

RSpec.describe Badges::AwardCommunityWellness, type: :service do
  let(:user) { create(:user) }

  def create_wellness_badge(weeks)
    create(:badge, title: "#{weeks} Week Community Wellness Streak",
                   slug: "#{weeks}-week-community-wellness-streak")
  end

  def query_result(user, weeks:, counts:)
    {
      "user_id" => user.id,
      "serialized_weeks_ago" => weeks.join(","),
      "serialized_comment_counts" => counts.join(",")
    }
  end

  # Keep query-to-award coverage through week 32; the query spec covers filtering
  # and serialization, while the service examples below cover streak decisions.
  it "awards the longest streak through the real comment query", :aggregate_failures do
    badge = create_wellness_badge(32)
    article = create(:article, user: user)
    32.times do |week|
      2.times { create_comment_time_ago(user.id, (8 + (week * 7)).days.ago, commentable: article) }
    end

    expect { described_class.call }.to change(BadgeAchievement, :count).by(1)
    expect(user.reload.badges).to contain_exactly(badge)
  end

  context "with serialized query results" do
    let(:results) { [] }

    before do
      allow(Comments::CommunityWellnessQuery).to receive(:call).and_return(results)
    end

    it "awards every milestone to its user in one batch", :aggregate_failures do
      users_by_week = [1, 2, 4, 8, 16, 24, 32].to_h do |weeks|
        create_wellness_badge(weeks)
        recipient = create(:user)
        results << query_result(recipient, weeks: (1..weeks).to_a, counts: Array.new(weeks, 2))
        [weeks, recipient]
      end

      expect { described_class.call }.to change(BadgeAchievement, :count).by(7)

      users_by_week.each do |weeks, recipient|
        message_key = case weeks
                      when 1 then "first"
                      when 32 then "longest"
                      else "other"
                      end
        achievement = recipient.badge_achievements.sole
        expect(achievement.badge.slug).to eq("#{weeks}-week-community-wellness-streak")
        expect(achievement.rewarding_context_message_markdown)
          .to eq(I18n.t("services.badges.community_wellness.#{message_key}", weeks: weeks))
      end
    end

    it "ignores the current week when calculating the streak", :aggregate_failures do
      badge = create_wellness_badge(2)
      results << query_result(user, weeks: [0, 1, 2], counts: [1, 2, 2])

      expect { described_class.call }.to change(BadgeAchievement, :count).by(1)
      expect(user.reload.badges).to contain_exactly(badge)
    end

    [
      { weeks: [1, 3, 4], counts: [2, 2, 2] },
      { weeks: [1, 2, 3, 4], counts: [2, 1, 2, 2] },
    ].each do |data|
      it "stops the streak at a missing or underqualified week in #{data}", :aggregate_failures do
        badge = create_wellness_badge(1)
        create_wellness_badge(2)
        create_wellness_badge(4)
        results << query_result(user, **data)

        expect { described_class.call }.to change(BadgeAchievement, :count).by(1)
        expect(user.reload.badges).to contain_exactly(badge)
      end
    end

    it "does not award a badge between milestones" do
      create_wellness_badge(2)
      results << query_result(user, weeks: [1, 2, 3], counts: [2, 2, 2])

      expect { described_class.call }.not_to change(BadgeAchievement, :count)
    end
  end
end
