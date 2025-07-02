module RateLimitCheckerHelper
  def self.new_user_message(thing)
    timeframe = I18n.t("helpers.rate_limit_checker_helper.day", count: Settings::RateLimit.user_considered_new_days)
    I18n.t("helpers.rate_limit_checker_helper.general", thing: thing, timeframe: timeframe)
  end

  # @return [Hash<Symbol,Hash<Symbol,Object>>] Each element of the returning hash *must* have the
  #         following keys: `:min`, `:placeholder`, `:title`, `:description`, and `:enabled`.
  def configurable_rate_limits
    {
      published_article_creation: {
        enabled: true,
        min: 0,
        placeholder: 9,
        title: I18n.t("helpers.rate_limit_checker_helper.published.title"),
        description: I18n.t("helpers.rate_limit_checker_helper.published.description")
      },
      published_article_antispam_creation: {
        enabled: true,
        min: 0,
        placeholder: 1,
        title: I18n.t("helpers.rate_limit_checker_helper.antispam.title"),
        description: RateLimitCheckerHelper.new_user_message(I18n.t("helpers.rate_limit_checker_helper.thing.posts"))
      },
      article_update: {
        enabled: true,
        min: 1,
        placeholder: 30,
        title: I18n.t("helpers.rate_limit_checker_helper.update.title"),
        description: I18n.t("helpers.rate_limit_checker_helper.update.description")
      },
      image_upload: {
        enabled: true,
        min: 0,
        placeholder: 9,
        title: I18n.t("helpers.rate_limit_checker_helper.upload.title"),
        description: I18n.t("helpers.rate_limit_checker_helper.upload.description")
      },
      user_update: {
        enabled: true,
        min: 1,
        placeholder: 5,
        title: I18n.t("helpers.rate_limit_checker_helper.user.title"),
        description: I18n.t("helpers.rate_limit_checker_helper.user.description")
      },
      follow_count_daily: {
        enabled: true,
        min: 0,
        placeholder: 500,
        title: I18n.t("helpers.rate_limit_checker_helper.follow.title"),
        description: I18n.t("helpers.rate_limit_checker_helper.follow.description")
      },
      reaction_creation: {
        enabled: true,
        min: 1,
        placeholder: 10,
        title: I18n.t("helpers.rate_limit_checker_helper.reaction.title"),
        description: I18n.t("helpers.rate_limit_checker_helper.reaction.description")
      },
      feedback_message_creation: {
        enabled: true,
        min: 1,
        placeholder: 5,
        title: I18n.t("helpers.rate_limit_checker_helper.feedback.title"),
        description: I18n.t("helpers.rate_limit_checker_helper.feedback.description")
      },
      comment_creation: {
        enabled: true,
        min: 0,
        placeholder: 9,
        title: I18n.t("helpers.rate_limit_checker_helper.comment.title"),
        description: I18n.t("helpers.rate_limit_checker_helper.comment.description")
      },
      comment_antispam_creation: {
        enabled: true,
        min: 0,
        placeholder: 1,
        title: I18n.t("helpers.rate_limit_checker_helper.comment_antispam.title"),
        description: RateLimitCheckerHelper.new_user_message(I18n.t("helpers.rate_limit_checker_helper.thing.comments"))
      },
      mention_creation: {
        enabled: true,
        min: 0,
        placeholder: 7,
        title: I18n.t("helpers.rate_limit_checker_helper.mention.title"),
        description: I18n.t("helpers.rate_limit_checker_helper.mention.description")
      },
      organization_creation: {
        enabled: true,
        min: 1,
        placeholder: 1,
        title: I18n.t("helpers.rate_limit_checker_helper.organization.title"),
        description: I18n.t("helpers.rate_limit_checker_helper.organization.description")
      },
      user_subscription_creation: {
        enabled: true,
        min: 0,
        placeholder: 3,
        title: I18n.t("helpers.rate_limit_checker_helper.subscription.title"),
        description: I18n.t("helpers.rate_limit_checker_helper.subscription.description")
      },
      email_recipient: {
        enabled: true,
        min: 0,
        placeholder: 5,
        title: I18n.t("helpers.rate_limit_checker_helper.recipient.title"),
        description: I18n.t("helpers.rate_limit_checker_helper.recipient.description")
      },
      send_email_confirmation: {
        enabled: true,
        min: 1,
        placeholder: 2,
        title: I18n.t("helpers.rate_limit_checker_helper.confirmation.title"),
        description: I18n.t("helpers.rate_limit_checker_helper.confirmation.description")
      }
    }
  end
end
