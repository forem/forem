require "rails_helper"

RSpec.describe "Article Badge Reputation Bonus", type: :model do
  let(:user) { create(:user) }
  let(:article) { create(:article, user: user) }
  # Use different titles/slugs to avoid uniqueness validation issues if factories aren't enough
  let(:badge1) { create(:badge, title: "Badge 1", bonus_weight: 10) }
  let(:badge2) { create(:badge, title: "Badge 2", bonus_weight: 6) }

  it "calculates the reputation bonus as the square root of the sum of badge weights" do
    # Sum of weights = 10 + 6 = 16. Sqrt(16) = 4.
    create(:badge_achievement, user: user, badge: badge1)
    create(:badge_achievement, user: user, badge: badge2)

    # Initial update
    article.update_score
    score_with_badges = article.score

    # Remove achievements
    user.badge_achievements.destroy_all
    # Reload user to clear associations cache
    user.reload
    article.update_score
    score_without_badges = article.score

    expect(score_with_badges - score_without_badges).to eq(4)
  end

  it "handles zero bonus weight correctly" do
    create(:badge_achievement, user: user, badge: create(:badge, title: "Zero Badge", bonus_weight: 0))
    article.update_score
    score_with_zero_badge = article.score

    user.badge_achievements.destroy_all
    user.reload
    article.update_score
    score_without_badges = article.score

    expect(score_with_zero_badge).to eq(score_without_badges)
  end
end
