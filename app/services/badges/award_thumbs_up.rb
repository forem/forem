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

      user_thumbsup_counts = Reaction
        .where(category: "thumbsup", reactable_type: "Article")
        .group(:user_id)
        .having("COUNT(*) >= ?", MIN_THRESHOLD)
        .order(Arel.sql("COUNT(*) DESC"))
        .count

      user_thumbsup_counts.each do |user_id, count|
        THUMBS_UP_BADGES.each do |threshold, _|
          break unless count >= threshold

          badge_id = badge_ids[threshold]
          next unless badge_id
          next unless (user = User.find_by(id: user_id))

          user.badge_achievements.create(
            badge_id: badge_id,
            rewarding_context_message_markdown: generate_message(threshold: threshold),
          )
        end
      end
    end

    def self.fetch_badge_ids
      THUMBS_UP_BADGES.transform_values do |title|
        Badge.find_by(title: title)&.id
      end
    end

    def self.generate_message(threshold:)
      I18n.t("services.badges.thumbs_up", count: threshold)
    end
  end
end
