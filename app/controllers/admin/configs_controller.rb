module Admin
  class ConfigsController < Admin::ApplicationController
    CAMPAIGN_PARAMS =
      %i[
        campaign_call_to_action
        campaign_featured_tags
        campaign_hero_html_variant_name
        campaign_sidebar_enabled
        campaign_sidebar_image
        campaign_url
        campaign_articles_require_approval
        campaign_articles_expiry_time
      ].freeze

    COMMUNITY_PARAMS =
      %i[
        community_name
        community_emoji
        collective_noun
        collective_noun_disabled
        community_description
        community_member_label
        community_copyright_start_year
        staff_user_id
        tagline
        experience_low
        experience_high
      ].freeze

    NEWSLETTER_PARAMS =
      %i[
        mailchimp_api_key
        mailchimp_community_moderators_id
        mailchimp_newsletter_id
        mailchimp_sustaining_members_id
        mailchimp_tag_moderators_id
      ].freeze

    RATE_LIMIT_PARAMS =
      %i[
        rate_limit_comment_creation
        rate_limit_email_recipient
        rate_limit_follow_count_daily
        rate_limit_image_upload
        rate_limit_published_article_creation
        rate_limit_published_article_antispam_creation
        rate_limit_organization_creation
        rate_limit_user_subscription_creation
        rate_limit_article_update
        rate_limit_user_update
        rate_limit_feedback_message_creation
        rate_limit_listing_creation
        rate_limit_reaction_creation
        rate_limit_send_email_confirmation
      ].freeze

    MASCOT_PARAMS =
      %i[
        mascot_image_description
        mascot_image_url
        mascot_footer_image_url
        mascot_footer_image_width
        mascot_footer_image_height
        mascot_user_id
      ].freeze

    IMAGE_PARAMS =
      %i[
        favicon_url
        logo_png
        logo_svg
        main_social_image
        secondary_logo_url
        left_navbar_svg_icon
        right_navbar_svg_icon
      ].freeze

    ONBOARDING_PARAMS =
      %i[
        onboarding_logo_image
        onboarding_background_image
        onboarding_taskcard_image
        suggested_tags
        suggested_users
        prefer_manual_suggested_users
      ].freeze

    JOB_PARAMS =
      %i[
        jobs_url
        display_jobs_banner
      ].freeze

    ALLOWED_PARAMS =
      %i[
        ga_tracking_id
        periodic_email_digest_max
        periodic_email_digest_min
        sidebar_tags
        twitter_hashtag
        shop_url
        payment_pointer
        stripe_api_key
        stripe_publishable_key
        health_check_token
        feed_style
        feed_strategy
        default_font
        sponsor_headline
        public
        twitter_key
        twitter_secret
        github_key
        github_secret
        facebook_key
        facebook_secret
        apple_client_id
        apple_key_id
        apple_pem
        apple_team_id
        auth_providers_to_enable
        invite_only_mode
        allow_email_password_registration
        require_captcha_for_email_password_registration
        primary_brand_color_hex
        spam_trigger_terms
        recaptcha_site_key
        recaptcha_secret_key
        video_encoder_key
        tag_feed_minimum_score
        home_feed_minimum_score
        allowed_registration_email_domains
        display_email_domain_allow_list_publicly
      ].freeze
    include SiteConfigParams

    EMOJI_ONLY_FIELDS = %w[community_emoji].freeze
    IMAGE_FIELDS =
      %w[
        main_social_image
        logo_png
        secondary_logo_url
        campaign_sidebar_image
        mascot_image_url
        mascot_footer_image_url
        onboarding_logo_image
        onboarding_background_image
        onboarding_taskcard_image
      ].freeze

    VALID_URL = %r{\A(http|https)://([/|.\w\s-])*.[a-z]{2,5}(:[0-9]{1,5})?(/.*)?\z}.freeze

    layout "admin"

    before_action :extra_authorization_and_confirmation, only: [:create]

    def show
      @confirmation_text = confirmation_text
    end

    def create
      result = SiteConfigs::Upsert.call(site_config_params)
      if result.success?
        Audit::Logger.log(:internal, current_user, params.dup)
        bust_content_change_caches
        redirect_to admin_config_path, notice: "Site configuration was successfully updated."
      else
        redirect_to admin_config_path, alert: "😭 #{result.errors.to_sentence}"
      end
    end

    private

    def confirmation_text
      "My username is @#{current_user.username} and this action is 100% safe and appropriate."
    end

    def raise_confirmation_mismatch_error
      raise ActionController::BadRequest.new, "The confirmation key does not match"
    end

    def extra_authorization_and_confirmation
      not_authorized unless current_user.has_role?(:super_admin)
      raise_confirmation_mismatch_error if params.require(:confirmation) != confirmation_text
    end
  end
end
