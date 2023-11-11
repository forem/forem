require "rails_helper"

RSpec.describe Badges::AwardThumbsUp, type: :service do
  let!(:thumbs_up_badges) { described_class::THUMBS_UP_BADGES }
  let!(:badge_count) { thumbs_up_badges.keys.count }
  let!(:users) { create_list(:user, badge_count * 2) } # Two sets of users
  let!(:max_reaction_threshold) { thumbs_up_badges.keys.max }
  let!(:articles) { create_list(:article, max_reaction_threshold) } # Enough articles for max no. of reactions
  let!(:badge_thresholds) { {} }

  before do
    # Create badges and build the badge_thresholds hash
    thumbs_up_badges.each_with_index do |(threshold, badge_title), _index|
      badge = create(:badge, title: badge_title)
      badge_thresholds[threshold] = badge.id
    end

    # Create reactions for each set of users
    # First set hits the threshold, second set is off by one
    users.each_with_index do |user, index|
      reaction_count = if index < badge_count
                         thumbs_up_badges.keys[index] # Enough reactions for the badge
                       else
                         thumbs_up_badges.keys[index - badge_count] - 1 # One less than needed
                       end

      # Create reactions for the user
      articles.sample(reaction_count).each do |article|
        create(
          :reaction,
          user_id: user.id,
          reactable_id: article.id,
          reactable_type: "Article",
          category: "thumbsup",
        )
      end
    end
  end

  it "awards the correct thumbs up badges to users" do
    expected_badge_count_first_set = thumbs_up_badges.keys.take(badge_count).sum
    expected_badge_count_second_set = thumbs_up_badges.keys.take(badge_count - 1).sum
    total_expected_badge_count = expected_badge_count_first_set + expected_badge_count_second_set

    expect do
      described_class.call
    end.to change(BadgeAchievement, :count).by(total_expected_badge_count)

    users.each_with_index do |user, index|
      badge_thresholds.each do |threshold, badge_id|
        if user.reactions.where(category: "thumbsup").count >= threshold
          expect(user.reload.badge_achievements.exists?(badge_id: badge_id)).to be true
        else
          expect(user.reload.badge_achievements.exists?(badge_id: badge_id)).to be false
        end
      end

      next unless index >= badge_count

      # Users in the second set should not have the badge corresponding to their index
      non_eligible_badge_threshold = thumbs_up_badges.keys[index - badge_count]
      non_eligible_badge_id = badge_thresholds[non_eligible_badge_threshold]
      expect(user.reload.badge_achievements.exists?(badge_id: non_eligible_badge_id)).to be false
    end
  end
end
