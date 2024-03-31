module Badges
  class AwardThumbsUp
    THUMBS_UP_BADGES = {
      100 => "100 Thumbs Up Milestone",
      500 => "500 Thumbs Up Milestone",
      1000 => "1,000 Thumbs Up Milestone",
      5000 => "5,000 Thumbs Up Milestone",
      10_000 => "10,000 Thumbs Up Milestone"
    }.freeze

    MIN_THRESHOLD = THUMBS_UP_BADGES.keys.min

    def self.call
      badge_ids = fetch_badge_ids

      # Early return if any badge is not found
      return if badge_ids.values.any?(&:nil?)

      user_thumbsup_counts = get_user_thumbsup_counts

      user_thumbsup_counts.each do |user_id, count|
        THUMBS_UP_BADGES.each do |threshold, _|
          break unless count >= threshold

          badge_id = badge_ids[threshold]
          next unless badge_id

          BadgeAchievement.create(
            user_id: user_id,
            badge_id: badge_id,
            rewarding_context_message_markdown: generate_message(threshold: threshold),
          )
        end
      end
    end

    def self.get_user_thumbsup_counts
      Reaction.where(category: "thumbsup", reactable_type: "Article")
        .group(:user_id)
        .having("COUNT(*) >= ?", MIN_THRESHOLD)
        .order(Arel.sql("COUNT(*) DESC"))
        .count
    end

    def self.fetch_badge_ids
      Badge.where(title: THUMBS_UP_BADGES.values).each_with_object({}) do |badge, hash|
        hash[THUMBS_UP_BADGES.key(badge.title)] = badge[:id]
      end
    end

    def self.generate_message(threshold:)
      I18n.t("services.badges.thumbs_up", count: threshold)
    end
  end
end
