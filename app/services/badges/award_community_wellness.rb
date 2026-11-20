module Badges
  class AwardCommunityWellness
    REWARD_STREAK_WEEKS = [1, 2, 4, 8, 16, 24, 32].freeze
    BATCH_SIZE = 200

    def self.call
      results = Comments::CommunityWellnessQuery.call
      return if results.empty?

      badges_by_weeks = fetch_badges_by_weeks
      return if badges_by_weeks.empty?

      pending_awards = collect_pending_awards(results, badges_by_weeks)
      return if pending_awards.empty?

      award_pending(pending_awards, badges_by_weeks.values)
    end

    def self.fetch_badges_by_weeks
      slug_to_weeks = REWARD_STREAK_WEEKS.index_by { |weeks| "#{weeks}-week-community-wellness-streak" }
      Badge.select(:id, :slug, :allow_multiple_awards)
        .where(slug: slug_to_weeks.keys)
        .index_by { |badge| slug_to_weeks[badge.slug] }
    end

    def self.collect_pending_awards(results, badges_by_weeks)
      results.filter_map do |hash|
        week_streak = active_streak_weeks(hash)
        next unless REWARD_STREAK_WEEKS.include?(week_streak)

        badge = badges_by_weeks[week_streak]
        next unless badge

        [hash["user_id"].to_i, week_streak, badge]
      end
    end

    def self.active_streak_weeks(hash)
      weeks_ago = hash["serialized_weeks_ago"].split(",").map(&:to_i)
      comment_counts = hash["serialized_comment_counts"].split(",").map(&:to_i)

      week_streak = 0
      weeks_ago.each_with_index do |week, index|
        next if week.zero?
        next unless comment_counts[index].to_i > 1
        next unless week_streak + 1 == week

        week_streak = week
      end
      week_streak
    end

    def self.award_pending(pending_awards, badges)
      single_award_badge_ids = badges.reject(&:allow_multiple_awards).map(&:id)
      messages_by_weeks = REWARD_STREAK_WEEKS.index_with { |weeks| generate_message(weeks: weeks) }

      pending_awards.each_slice(BATCH_SIZE) do |batch|
        batch_user_ids = batch.map(&:first).uniq
        valid_user_ids = User.where(id: batch_user_ids).ids.to_set
        existing_pairs = if single_award_badge_ids.any?
                           BadgeAchievement.where(user_id: batch_user_ids, badge_id: single_award_badge_ids)
                             .pluck(:user_id, :badge_id)
                             .to_set
                         else
                           Set.new
                         end

        batch.each do |user_id, week_streak, badge|
          next unless valid_user_ids.include?(user_id)
          next if !badge.allow_multiple_awards && existing_pairs.include?([user_id, badge.id])

          BadgeAchievement.create(
            user_id: user_id,
            badge_id: badge.id,
            rewarding_context_message_markdown: messages_by_weeks[week_streak],
          )
        end
      end
    end

    def self.generate_message(weeks:)
      case weeks
      when 1
        I18n.t("services.badges.community_wellness.first")
      when REWARD_STREAK_WEEKS.last
        I18n.t("services.badges.community_wellness.longest")
      else
        I18n.t("services.badges.community_wellness.other", weeks: weeks)
      end
    end
  end
end
