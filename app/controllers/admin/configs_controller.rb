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

    VALID_URL = %r{\A(http|https)://([/|.|\w|\s|-])*.[a-z]{2,5}(:[0-9]{1,5})?(/.*)?\z}.freeze

    layout "admin"

    before_action :extra_authorization_and_confirmation, only: [:create]
    before_action :validate_inputs, only: [:create]
    before_action :validate_emoji, only: [:create], if: -> { params[:site_config].keys & EMOJI_ONLY_FIELDS }
    before_action :validate_image_urls, only: [:create], if: -> { params[:site_config].keys & IMAGE_FIELDS }
    after_action :bust_content_change_caches, only: [:create]

    def show
      @confirmation_text = confirmation_text
    end

    def create
      clean_up_params

      config_params.each do |key, value|
        if key == "auth_providers_to_enable"
          update_enabled_auth_providers(value) unless value.class.name != "String"
        elsif value.is_a?(Array)
          SiteConfig.public_send("#{key}=", value.reject(&:blank?)) unless value.empty?
        elsif value.respond_to?(:to_h)
          SiteConfig.public_send("#{key}=", value.to_h) unless value.empty?
        else
          SiteConfig.public_send("#{key}=", value.strip) unless value.nil?
        end
      end

      redirect_to admin_config_path, notice: "Site configuration was successfully updated."
    end

    private

    def confirmation_text
      "My username is @#{current_user.username} and this action is 100% safe and appropriate."
    end

    def config_params
      all_params = ALLOWED_PARAMS |
        CAMPAIGN_PARAMS |
        COMMUNITY_PARAMS |
        NEWSLETTER_PARAMS |
        RATE_LIMIT_PARAMS |
        MASCOT_PARAMS |
        IMAGE_PARAMS |
        ONBOARDING_PARAMS |
        JOB_PARAMS

      has_emails = params.dig(:site_config, :email_addresses).present?
      params[:site_config][:email_addresses][:default] = ApplicationConfig["DEFAULT_EMAIL"] if has_emails
      params&.require(:site_config)&.permit(
        all_params,
        authentication_providers: [],
        social_media_handles: SiteConfig.social_media_handles.keys,
        email_addresses: SiteConfig.email_addresses.keys,
        meta_keywords: SiteConfig.meta_keywords.keys,
        credit_prices_in_cents: SiteConfig.credit_prices_in_cents.keys,
      )
    end

    def raise_confirmation_mismatch_error
      raise ActionController::BadRequest.new, "The confirmation key does not match"
    end

    def extra_authorization_and_confirmation
      not_authorized unless current_user.has_role?(:super_admin)
      raise_confirmation_mismatch_error if params.require(:confirmation) != confirmation_text
    end

    def validate_inputs
      errors = []
      errors << "Brand color must be darker for accessibility." if brand_contrast_too_low
      errors << "Brand color must be be a 6 character hex (starting with #)." if brand_color_not_hex
      errors << "Allowed emails must be list of domains." if allowed_domains_include_improper_format
      redirect_to admin_config_path, alert: "😭 #{errors.to_sentence}" if errors.any?
    end

    def validate_emoji
      emoji_params = config_params.slice(*EMOJI_ONLY_FIELDS).to_h
      errors = emoji_params.filter_map do |field, value|
        non_emoji_characters = value.downcase.gsub(EmojiRegex::RGIEmoji, "")
        "#{field} contains invalid emoji" if non_emoji_characters.present?
      end
      redirect_to admin_config_path, alert: "😭 #{errors.to_sentence}" if errors.any?
    end

    def validate_image_urls
      image_params = config_params.slice(*IMAGE_FIELDS).to_h
      errors = image_params.filter_map do |field, url|
        "#{field} must be a valid URL" unless url.blank? || valid_image_url(url)
      end
      redirect_to admin_config_path, alert: "😭 #{errors.to_sentence}" if errors.any?
    end

    def clean_up_params
      config = params[:site_config]
      return unless config

      %i[sidebar_tags suggested_tags suggested_users].each do |param|
        config[param] = config[param]&.downcase&.delete(" ") if config[param]
      end
      config[:credit_prices_in_cents]&.transform_values!(&:to_i)
    end

    def provider_keys_missing(entry)
      SiteConfig.public_send("#{entry}_key").blank? || SiteConfig.public_send("#{entry}_secret").blank?
    end

    def invalid_provider_entry(entry)
      entry.blank? || helpers.available_providers_array.exclude?(entry) ||
        provider_keys_missing(entry)
    end

    def email_login_disabled_with_one_or_less_auth_providers(enabled_providers)
      !SiteConfig.allow_email_password_login && enabled_providers.count <= 1
    end

    def update_enabled_auth_providers(value)
      enabled_providers = []
      value.split(",").each do |entry|
        enabled_providers.push(entry) unless invalid_provider_entry(entry)
      end
      SiteConfig.public_send("authentication_providers=", enabled_providers) unless
        email_login_disabled_with_one_or_less_auth_providers(enabled_providers)
    end

    # Validations
    def brand_contrast_too_low
      hex = params.dig(:site_config, :primary_brand_color_hex)
      hex.present? && Color::Accessibility.new(hex).low_contrast?
    end

    def brand_color_not_hex
      hex = params.dig(:site_config, :primary_brand_color_hex)
      hex.present? && !hex.match?(/\A#(\h{6}|\h{3})\z/)
    end

    def allowed_domains_include_improper_format
      domains = params.dig(:site_config, :allowed_registration_email_domains)
      return unless domains

      domains_array = domains.delete(" ").split(",")
      valid_domains = domains_array
        .select { |d| d.match?(/^[a-zA-Z0-9][a-zA-Z0-9-]{1,61}[a-zA-Z0-9](?:\.[a-zA-Z]{2,})+$/) }
      valid_domains.size != domains_array.size
    end

    def valid_image_url(url)
      url.match?(VALID_URL)
    end
  end
end
