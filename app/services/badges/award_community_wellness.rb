module Badges
  class AwardCommunityWellness
    REWARD_STREAK_WEEKS = [1, 2, 4, 8, 16, 32].freeze

    def self.call
      new.call
    end

    def call
      # These are the users 'eligible' to be awarded the badge, which attempts
      # to make the subsequent queries/iterations more performant by using a
      # subset of users and not large joins.
      users = User.where(id: multiple_comment_user_ids)

      users.find_each do |user|
        week_streak = 0
        (1..REWARD_STREAK_WEEKS.last).each do |week|
          break unless wellness_goal_x_weeks_ago?(user, week)

          week_streak += 1
        end

        next unless REWARD_STREAK_WEEKS.include?(week_streak)

        Rails.logger.debug "SUCCESS: Awarding streak of #{week_streak} weeks to #{user.username}"

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

    # user_ids that posted more than one comment last week
    def multiple_comment_user_ids
      Comment.select(:user_id, :created_at)
        .where("created_at > ?", 1.week.ago)
        .group(:user_id)
        .having("COUNT(*) > ?", 1)
        .pluck(:user_id)
    end

    # Returns whether or not a user qualifies for the badge for `num` week ago
    def wellness_goal_x_weeks_ago?(user, num)
      start_date = num.weeks.ago
      end_date = (num - 1).weeks.ago

      # Fetch all the user's comments in the `num` timeframe
      user_comments = user.comments
        .includes(:reactions)
        .where("created_at > ? AND created_at < ?", start_date, end_date)

      # Count the number of comments a user has made in this timeframe whoose
      # reactions don't include a thumbsdown/vomit. It doesn't matter if the
      # comment has many positive reactions, if the comment has one negative
      # reaction it won't count for the wellness badge.
      negative_reactions = %w[thumbsdown vomit]
      unflagged_comments = user_comments.count do |c|
        c.reactions.map(&:category).exclude?(negative_reactions)
      end

      # Two or more unflagged comments in this timeframe qualify for the badge
      unflagged_comments > 1
    end

    def generate_message
      # TODO: Use correct message
      return I18n.t("services.badges.award_streak.longest") if weeks == LONGEST_STREAK_WEEKS

      I18n.t("services.badges.award_streak.message", count: weeks * 2)
    end
  end
end
