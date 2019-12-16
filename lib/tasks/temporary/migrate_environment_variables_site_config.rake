# Migrate environment variables to SiteConfig

ENV_VARS_TO_SITE_CONFIG = {
  DEVTO_USER_ID: :staff_user_id,
  DEFAULT_SITE_EMAIL: :default_site_email,
  SITE_TWITTER_HANDLE: :social_networks_handle,

  MAIN_SOCIAL_IMAGE: :main_social_image,
  FAVICON_URL: :favicon_url,
  LOGO_SVG: :logo_svg,

  RATE_LIMIT_FOLLOW_COUNT_DAILY: :rate_limit_follow_count_daily,

  GA_VIEW_ID: :ga_view_id,
  GA_FETCH_RATE: :ga_fetch_rate,

  MAILCHIMP_NEWSLETTER_ID: :mailchimp_newsletter_id,
  MAILCHIMP_SUSTAINING_MEMBERS_ID: :mailchimp_sustaining_members_id,
  MAILCHIMP_TAG_MODERATORS_ID: :mailchimp_tag_moderators_id,
  MAILCHIMP_COMMUNITY_MODERATORS_ID: :mailchimp_community_moderators_id,

  PERIODIC_EMAIL_DIGEST_MAX: :periodic_email_digest_max,
  PERIODIC_EMAIL_DIGEST_MIN: :periodic_email_digest_min
}.freeze

def display_vars(env_var, config_var)
  env_var_value = "ApplicationConfig[#{env_var}] = #{ApplicationConfig[env_var]}"
  config_var_value = "SiteConfig.#{config_var} = #{SiteConfig.public_send(config_var)}"
  Rails.logger.info([env_var_value, config_var_value].join(", "))
end

namespace :site_config do
  desc "Display variables values"
  task display_variables: :environment do
    ENV_VARS_TO_SITE_CONFIG.each do |env_var, config_var|
      display_vars(env_var, config_var)
    end
  end

  desc "Copy non empty environment variables over to the site configuration"
  task migrate_environment_variables: :environment do
    ENV_VARS_TO_SITE_CONFIG.each do |env_var, config_var|
      if ApplicationConfig[env_var].blank? || ApplicationConfig[env_var] == "Optional"
        Rails.logger.info("Skipping #{env_var} because it is empty...")
        next
      end

      Rails.logger.info("Copying ApplicationConfig[#{env_var}] to SiteConfig.#{config_var}...")
      SiteConfig.public_send("#{config_var}=", ApplicationConfig[env_var])
    end

    SiteConfig.clear_cache

    ENV_VARS_TO_SITE_CONFIG.each do |env_var, config_var|
      display_vars(env_var, config_var)
    end
  end
end
