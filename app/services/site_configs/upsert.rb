module SiteConfigs
  module Upsert
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

    def self.call(configs)
      @configs = configs
      @errors = []
      clean_up_params
      validate_inputs
      validate_emoji
      validate_image_urls

      return { result: "errors", errors: @errors.to_sentence } if @errors.flatten.any?

      @configs.each do |key, value|
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
    end

    def self.clean_up_params
      %i[sidebar_tags suggested_tags suggested_users].each do |param|
        @configs[param] = @configs[param]&.downcase&.delete(" ") if @configs[param]
      end
      @configs[:credit_prices_in_cents]&.transform_values!(&:to_i)
    end

    def self.validate_inputs
      @errors << "Brand color must be darker for accessibility." if brand_contrast_too_low
      @errors << "Brand color must be be a 6 character hex (starting with #)." if brand_color_not_hex
      @errors << "Allowed emails must be list of domains." if allowed_domains_include_improper_format
    end

    def self.validate_emoji
      emoji_params = @configs.slice(*EMOJI_ONLY_FIELDS).to_h
      @errors << emoji_params.filter_map do |field, value|
        non_emoji_characters = value.downcase.gsub(EmojiRegex::RGIEmoji, "")
        "#{field} contains invalid emoji" if non_emoji_characters.present?
      end
    end

    def self.validate_image_urls
      image_params = @configs.slice(*IMAGE_FIELDS).to_h
      @errors << image_params.filter_map do |field, url|
        "#{field} must be a valid URL" unless url.blank? || valid_image_url(url)
      end
    end

    def self.update_enabled_auth_providers(value)
      enabled_providers = []
      value.split(",").each do |entry|
        enabled_providers.push(entry) unless invalid_provider_entry(entry)
      end
      SiteConfig.public_send("authentication_providers=", enabled_providers) unless
        email_login_disabled_with_one_or_less_auth_providers(enabled_providers)
    end

    def self.email_login_disabled_with_one_or_less_auth_providers(enabled_providers)
      !SiteConfig.allow_email_password_login && enabled_providers.count <= 1
    end

    def self.invalid_provider_entry(entry)
      entry.blank? || Authentication::Providers.available.map(&:to_s).exclude?(entry)
    end

    # Validations
    def self.brand_contrast_too_low
      hex = @configs[:primary_brand_color_hex]
      hex.present? && Color::Accessibility.new(hex).low_contrast?
    end

    def self.brand_color_not_hex
      hex = @configs[:primary_brand_color_hex]
      hex.present? && !hex.match?(/\A#(\h{6}|\h{3})\z/)
    end

    def self.allowed_domains_include_improper_format
      domains = @configs[:allowed_registration_email_domains]
      return unless domains

      domains_array = domains.delete(" ").split(",")
      valid_domains = domains_array
        .select { |d| d.match?(/^[a-zA-Z0-9][a-zA-Z0-9-]{1,61}[a-zA-Z0-9](?:\.[a-zA-Z]{2,})+$/) }
      valid_domains.size != domains_array.size
    end

    def self.valid_image_url(url)
      url.match?(VALID_URL)
    end
  end
end
