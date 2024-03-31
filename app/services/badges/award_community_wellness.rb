module Badges
  class AwardCommunityWellness
    REWARD_STREAK_WEEKS = [1, 2, 4, 8, 16, 24, 32].freeze

    def self.call
      # These are the users 'eligible' to be awarded the badge
      results = Comments::CommunityWellnessQuery.call

      results.each do |hash|
        # Parse the serialized results that come from the query
        weeks_ago = hash["serialized_weeks_ago"].split(",").map(&:to_i)
        comment_counts = hash["serialized_comment_counts"].split(",").map(&:to_i)

        # `weeks_ago` can have values like the following:
        #    - [1,2,10,11,12]
        #    - [0,5]
        #    - [0,1,2,3,4,5,6,7,8]
        #    - [1,4,17]
        # We only care for active streak (starting at 1) so we need to filter
        # these to check how far back the (continuous) streak goes
        week_streak = 0
        weeks_ago.each_with_index do |week, index|
          # Week 0 are comments that exist but aren't at least 1 week old yet
          next if week.zero?

          # Must have 2 or more non-flagged comments posted on that week
          next unless comment_counts[index] > 1

          # Must be a consecutive streak
          next unless week_streak + 1 == week

          week_streak = week
        end

        # Check that the current streak matches a reward level
        # Otherwise continue with next iteration (next user in query results)
        next unless REWARD_STREAK_WEEKS.include?(week_streak)
        next unless (user = User.find_by(id: hash["user_id"]))

        badge_slug = "#{week_streak}-week-community-wellness-streak"
        next unless (badge_id = Badge.id_for_slug(badge_slug))

        user.badge_achievements.create(
          badge_id: badge_id,
          rewarding_context_message_markdown: generate_message(weeks: week_streak),
        )
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
