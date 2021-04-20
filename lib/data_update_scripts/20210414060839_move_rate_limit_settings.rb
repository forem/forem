module DataUpdateScripts
  class MoveRateLimitSettings
    RENAMED_RATE_LIMIT_SETTINGS = %w[
      article_update
      comment_antispam_creation
      comment_creation
      email_recipient
      feedback_message_creation
      follow_count_daily
      image_upload
      listing_creation
      organization_creation
      published_article_antispam_creation
      published_article_creation
      reaction_creation
      send_email_confirmation
      user_subscription_creation
      user_update
    ].freeze

    def run
      return if Settings::RateLimit.any?

      RENAMED_RATE_LIMIT_SETTINGS.each do |setting|
        Settings::RateLimit.public_send(
          "#{setting}=",
          SiteConfig.public_send("rate_limit_#{setting}"),
        )
      end

      Settings::RateLimit.spam_trigger_terms = SiteConfig.spam_trigger_terms
      Settings::RateLimit.user_considered_new_days =
        SiteConfig.user_considered_new_days
    end
  end
end
