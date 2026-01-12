module ScheduledAutomations
  ##
  # Service that awards badges to users who have posted their first post
  # under a specific organization since the last time the automation was run.
  #
  # This is specifically for first posts under an organization, not first posts overall.
  # Use the action "award_first_org_post_badge" in ScheduledAutomation.
  #
  # @example Award badges for first posts under an organization
  #   automation = ScheduledAutomation.find(1)
  #   result = ScheduledAutomations::FirstPostBadgeAwarder.call(automation)
  #   puts "Awarded #{result.users_awarded} badges"
  class FirstPostBadgeAwarder
    Result = Struct.new(:success?, :users_awarded, :error_message, keyword_init: true)

    class << self
      def call(automation)
        new(automation).call
      end
    end

    def initialize(automation)
      @automation = automation
      @organization_id = automation.action_config["organization_id"]&.to_i
      @badge_slug = automation.action_config["badge_slug"]

      # Look back 15 minutes to overlapping intervals to prevent misses
      last_run = automation.last_run_at || Time.at(0)
      @since_time = last_run == Time.at(0) ? last_run : last_run - 15.minutes
    end

    def call
      validate_config!

      badge_id = Badge.id_for_slug(@badge_slug)
      unless badge_id
        return Result.new(
          success?: false,
          users_awarded: 0,
          error_message: "Badge with slug '#{@badge_slug}' not found",
        )
      end

      organization = Organization.find_by(id: @organization_id)
      unless organization
        return Result.new(
          success?: false,
          users_awarded: 0,
          error_message: "Organization with id '#{@organization_id}' not found",
        )
      end

      users_awarded = award_badges_to_first_post_authors(organization, badge_id)

      Result.new(
        success?: true,
        users_awarded: users_awarded,
        error_message: nil,
      )
    rescue StandardError => e
      Result.new(
        success?: false,
        users_awarded: 0,
        error_message: "#{e.class}: #{e.message}",
      )
    end

    private

    def validate_config!
      if @organization_id.nil?
        raise ArgumentError, "organization_id is required in action_config"
      end

      return if @badge_slug.present?

      raise ArgumentError, "badge_slug is required in action_config"
    end

    def award_badges_to_first_post_authors(organization, badge_id)
      # Find all published articles under this organization since last run
      recent_articles = Article.published
        .where(organization_id: organization.id)
        .where("published_at > ?", @since_time)
        .includes(:user)
        .order(published_at: :asc)

      return 0 if recent_articles.empty?

      users_awarded = 0

      # Group articles by user to find their first post under this org
      recent_articles.group_by(&:user_id).each do |user_id, articles|
        user = articles.first.user
        next if user.nil? || user.banished?

        # Find the user's earliest article in the recent set
        earliest_recent_article = articles.min_by(&:published_at)

        # Check if this is the user's first published article under this organization
        # by checking if they have any earlier published articles under this org (ever)
        # Note: We check < earliest_recent_article.published_at, so if they have an earlier one that was
        # picked up in a previous run (or missed), this will return true and we skip.
        has_earlier_post = Article.published
          .where(organization_id: organization.id, user_id: user_id)
          .where("published_at < ?", earliest_recent_article.published_at)
          .exists?

        # Only award badge if this is their first post under this org AND it's in the recent set
        next if has_earlier_post

        # Check if user already has this badge (to avoid duplicates)
        # We always check this regardless of badge settings to ensure idempotency of this automation
        existing_achievement = BadgeAchievement.find_by(
          user_id: user_id,
          badge_id: badge_id,
        )
        next if existing_achievement

        # Award the badge
        achievement = BadgeAchievement.create(
          user_id: user_id,
          badge_id: badge_id,
          rewarding_context_message_markdown: generate_message(organization, earliest_recent_article),
        )

        if achievement.persisted?
          user.touch
          users_awarded += 1
        end
      end

      users_awarded
    end

    def generate_message(organization, article)
      org_url = URL.organization(organization)
      article_url = URL.article(article)

      "Congratulations on posting your first article under [#{organization.name}](#{org_url})! " \
        "Your post was [#{article.title}](#{article_url})."
    end
  end
end
