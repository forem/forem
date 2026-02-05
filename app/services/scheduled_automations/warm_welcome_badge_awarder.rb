module ScheduledAutomations
  ##
  # Service that awards badges to users who leave wonderful comments in the Welcome Thread.
  # Every week on Friday, it checks for users who qualify based on their participation
  # in the most recent official welcome thread.
  #
  # This automation is not configurable - it runs automatically if the badge with
  # slug "warm-welcome" exists.
  #
  # @example Award badges for warm welcome comments
  #   automation = ScheduledAutomation.find(1)
  #   result = ScheduledAutomations::WarmWelcomeBadgeAwarder.call(automation)
  #   puts "Awarded #{result.users_awarded} badges"
  class WarmWelcomeBadgeAwarder
    Result = Struct.new(:success?, :users_awarded, :error_message, keyword_init: true)

    BADGE_SLUG = "warm-welcome".freeze
    LOOKBACK_DAYS = 7.5
    MIN_DAYS_BETWEEN_AWARDS = 6.5

    class << self
      def call(automation)
        new(automation).call
      end
    end

    def initialize(automation)
      @automation = automation
      @since_time = automation.last_run_at || LOOKBACK_DAYS.days.ago
    end

    def call
      badge_id = Badge.id_for_slug(BADGE_SLUG)
      unless badge_id
        return Result.new(
          success?: false,
          users_awarded: 0,
          error_message: "Badge with slug '#{BADGE_SLUG}' not found"
        )
      end

      welcome_thread = find_current_welcome_thread
      unless welcome_thread
        return Result.new(
          success?: true,
          users_awarded: 0,
          error_message: nil
        )
      end

      users_awarded = award_badges_to_qualifying_users(welcome_thread, badge_id)

      Result.new(
        success?: true,
        users_awarded: users_awarded,
        error_message: nil
      )
    rescue StandardError => e
      Result.new(
        success?: false,
        users_awarded: 0,
        error_message: "#{e.class}: #{e.message}"
      )
    end

    private

    def find_current_welcome_thread
      # Find the most recent welcome thread
      # Try from subforem context if available, otherwise just get the most recent one
      subforem_id = RequestStore.store[:subforem_id] if defined?(RequestStore) && RequestStore.store
      if subforem_id
        Article.cached_admin_published_with("welcome", subforem_id: subforem_id) ||
          Article.cached_admin_published_with("welcome")
      else
        Article.cached_admin_published_with("welcome")
      end
    end

    def award_badges_to_qualifying_users(welcome_thread, badge_id)
      # Find all comments in the welcome thread from the last 7.5 days
      cutoff_time = LOOKBACK_DAYS.days.ago
      recent_comments = Comment
                          .where(commentable: welcome_thread)
                          .where("created_at > ?", cutoff_time)
                          .where("created_at > ?", @since_time)
                          .includes(:user)
                          .order(created_at: :desc)

      return 0 if recent_comments.empty?

      users_awarded = 0
      assessed_user_ids = []

      recent_comments.find_each do |comment|
        next if comment.user.nil? || comment.user.banished?
        next if assessed_user_ids.include?(comment.user_id)

        # Check if user already received this badge recently (within the last 6.5 days)
        if recently_awarded?(comment.user_id, badge_id)
          assessed_user_ids << comment.user_id
          next
        end

        # Assess if the comment is helpful/contextual
        if qualifies_for_badge?(comment, welcome_thread)
          achievement = BadgeAchievement.create(
            user_id: comment.user_id,
            badge_id: badge_id,
            rewarding_context_message_markdown: generate_message(comment, welcome_thread)
          )

          if achievement.persisted?
            comment.user.touch
            users_awarded += 1
            assessed_user_ids << comment.user_id
          end
        end
      end

      users_awarded
    end

    def recently_awarded?(user_id, badge_id)
      # Check if user received this badge within the last 6.5 days (to be safe)
      cutoff = MIN_DAYS_BETWEEN_AWARDS.days.ago
      BadgeAchievement
        .where(user_id: user_id, badge_id: badge_id)
        .where("created_at > ?", cutoff)
        .exists?
    end

    def qualifies_for_badge?(comment, welcome_thread)
      # Skip if comment is deleted or hidden
      return false if comment.deleted
      return false if comment.hidden_by_commentable_user

      # Skip low quality comments
      return false if comment.score <= Comment::LOW_QUALITY_THRESHOLD

      # Check if comment is spam using existing spam detection
      return false if Ai::CommentCheck.new(comment).spam?

      # Use AI to assess if comment is helpful/contextual for welcome thread
      assessor = Ai::CommentHelpfulnessAssessor.new(comment, welcome_thread)
      assessor.helpful?
    end

    def generate_message(comment, welcome_thread)
      comment_url = URL.comment(comment)
      welcome_url = URL.article(welcome_thread)

      "Congratulations on leaving a wonderful comment in the [Welcome Thread](#{welcome_url})! " \
      "Your helpful comment contributed to making our community a welcoming place. " \
      "You are eligible to win this badge any week where you leave a substantive and helpful comment in the Welcome Thread." \
      "Pro tip: Leave more than one comment to increase your chances of getting this week's badge!"
    end
  end
end

