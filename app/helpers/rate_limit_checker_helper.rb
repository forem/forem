module RateLimitCheckerHelper
  def self.new_user_message(thing)
    timeframe = "day".pluralize(Settings::RateLimit.user_considered_new_days)
    I18n.t("helpers.rate_limit_checker_helper.how_many_thing_s_can_a_new", thing: thing, timeframe: timeframe)
  end

  def configurable_rate_limits
    {
      published_article_creation: {
        min: 0,
        placeholder: 9,
        title: I18n.t("helpers.rate_limit_checker_helper.limit_number_of_posts_crea"),
        description: I18n.t("helpers.rate_limit_checker_helper.how_many_posts_can_someone")
      },
      published_article_antispam_creation: {
        min: 0,
        placeholder: 1,
        title: I18n.t("helpers.rate_limit_checker_helper.limit_number_of_posts_crea2"),
        description: RateLimitCheckerHelper.new_user_message(I18n.t("helpers.rate_limit_checker_helper.thing.posts"))
      },
      article_update: {
        min: 1,
        placeholder: 30,
        title: I18n.t("helpers.rate_limit_checker_helper.limit_number_of_updates_to"),
        description: I18n.t("helpers.rate_limit_checker_helper.how_many_updates_can_someo")
      },
      image_upload: {
        min: 0,
        placeholder: 9,
        title: I18n.t("helpers.rate_limit_checker_helper.limit_number_of_images_upl"),
        description: I18n.t("helpers.rate_limit_checker_helper.how_many_images_can_someon")
      },
      user_update: {
        min: 1,
        placeholder: 5,
        title: I18n.t("helpers.rate_limit_checker_helper.limit_number_of_changes_so"),
        description: I18n.t("helpers.rate_limit_checker_helper.how_many_changes_can_someo")
      },
      follow_count_daily: {
        min: 0,
        placeholder: 500,
        title: I18n.t("helpers.rate_limit_checker_helper.limit_number_of_followers"),
        description: I18n.t("helpers.rate_limit_checker_helper.how_many_people_can_someon")
      },
      reaction_creation: {
        min: 1,
        placeholder: 10,
        title: I18n.t("helpers.rate_limit_checker_helper.limit_number_of_reactions"),
        description: I18n.t("helpers.rate_limit_checker_helper.how_many_times_can_someone")
      },
      feedback_message_creation: {
        min: 1,
        placeholder: 5,
        title: I18n.t("helpers.rate_limit_checker_helper.limit_number_of_times_some"),
        description: I18n.t("helpers.rate_limit_checker_helper.how_many_times_can_someone2")
      },
      comment_creation: {
        min: 0,
        placeholder: 9,
        title: I18n.t("helpers.rate_limit_checker_helper.limit_number_of_comments_c"),
        description: I18n.t("helpers.rate_limit_checker_helper.how_many_comments_can_some")
      },
      comment_antispam_creation: {
        min: 0,
        placeholder: 1,
        title: I18n.t("helpers.rate_limit_checker_helper.limit_number_of_comments_c2"),
        description: RateLimitCheckerHelper.new_user_message(I18n.t("helpers.rate_limit_checker_helper.thing.comments"))
      },
      mention_creation: {
        min: 0,
        placeholder: 7,
        title: I18n.t("helpers.rate_limit_checker_helper.limit_number_of_mentions_i"),
        description: I18n.t("helpers.rate_limit_checker_helper.how_many_times_can_someone3")
      },
      listing_creation: {
        min: 1,
        placeholder: 1,
        title: I18n.t("helpers.rate_limit_checker_helper.limit_number_of_listings_c"),
        description: I18n.t("helpers.rate_limit_checker_helper.how_many_listings_can_some")
      },
      organization_creation: {
        min: 1,
        placeholder: 1,
        title: I18n.t("helpers.rate_limit_checker_helper.limit_number_of_organizati"),
        description: I18n.t("helpers.rate_limit_checker_helper.how_many_organizations_can")
      },
      user_subscription_creation: {
        min: 0,
        placeholder: 3,
        title: I18n.t("helpers.rate_limit_checker_helper.limit_number_of_times_some2"),
        description: I18n.t("helpers.rate_limit_checker_helper.how_many_times_can_someone4")
      },
      email_recipient: {
        min: 0,
        placeholder: 5,
        title: I18n.t("helpers.rate_limit_checker_helper.limit_number_of_general_em"),
        description: I18n.t("helpers.rate_limit_checker_helper.how_many_emails_can_we_sen")
      },
      send_email_confirmation: {
        min: 1,
        placeholder: 2,
        title: I18n.t("helpers.rate_limit_checker_helper.limit_number_of_confirmati"),
        description: I18n.t("helpers.rate_limit_checker_helper.how_many_times_can_we_send")
      }
    }
  end
end
