module Badges
  class AwardThumbsUp
    THUMBS_UP_BADGES = {
      1 => "100-thumbs-up-milestone",
      2 => "500-thumbs-up-milestone",
      3 => "1-2c000-thumbs-up-milestone",
      4 => "5-2c000-thumbs-up-milestone",
      5 => "10-2c000-thumbs-up-milestone"
    }.freeze

    MIN_THRESHOLD = THUMBS_UP_BADGES.keys.min

    def self.call
      user_thumbsup_counts = Reaction
        .where(category: "thumbsup", reactable_type: "Article")
        .group(:user_id)
        .having("COUNT(*) >= ?", MIN_THRESHOLD)
        .order(Arel.sql("COUNT(*) DESC"))
        .count
      user_thumbsup_counts.each do |user_thumbsup_count|
        THUMBS_UP_BADGES.each do |threshold, badge_slug|
          break unless user_thumbsup_count.count >= threshold
          next unless (badge_id = Badge.id_for_slug(badge_slug))
          next unless (user = User.find_by(id: user_thumbsup_count[0]))

          user.badge_achievements.create(
            badge_id: badge_id,
            rewarding_context_message_markdown: generate_message(threshold: threshold),
          )
        end
      end
    end

    def self.generate_message(threshold:)
      I18n.t("services.badges.thumbs_up", count: threshold)
    end
  end
end
