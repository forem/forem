module Badges
  class AwardCommunityWellness
    REWARD_STREAK_WEEKS = [1, 2, 4, 8, 16, 32].freeze

    def self.call
      new.call
    end

    def call
      # These are the users 'eligible' to be awarded the badge
      results = Comments::CommunityWellnessQuery.call

      results.each do |hash|
        # Parse the serialized results that come from the query
        weeks_ago = hash["serialized_weeks_ago"].split(",").map(&:to_i)
        comment_counts = hash["serialized_comment_counts"].split(",").map(&:to_i)

        # `weeks_ago` can have values like the following:
        #    - [1,2,10,11,12]
        #    - [5]
        #    - [1,2,3,4,5,6,7,8]
        #    - [1,4,17]
        # We only care for active streak (starting at 1) so we need to filter
        # these to check how far back the (continuous) streak goes
        week_streak = []
        weeks_ago.each_with_index do |week, index|
          # Must have 2 or more non-flagged comments posted on that week
          next unless comment_counts[index] > 1

          # Must be a consecutive streak
          next unless week_streak.last.to_i + 1 == week

          week_streak << week
        end

        Rails.logger.debug { "Current streak (user_id #{hash['user_id']}): #{week_streak}" }

        # Check if the current streak matches a reward level
        next unless REWARD_STREAK_WEEKS.include?(week_streak.last)

        Rails.logger.debug { "SUCCESS: Awarding streak of #{week_streak.last} weeks to user_id #{hash['user_id']}" }

        # TODO: Actually award the badge

        # badge_slug = "#{week_streak}-week-wellness-streak"
        # return unless (badge_id = Badge.id_for_slug(badge_slug))

        # user.badge_achievements.create(
        #   badge_id: badge_id,
        #   rewarding_context_message_markdown: generate_message,
        # )
      end
    end

    private

    def generate_message
      # TODO: Use correct message
      return I18n.t("services.badges.award_streak.longest") if weeks == LONGEST_STREAK_WEEKS

      I18n.t("services.badges.award_streak.message", count: weeks * 2)
    end
  end
end
