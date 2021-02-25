module SiteConfigs
  class Upsert
    EMOJI_ONLY_FIELDS = %w[community_emoji].freeze
    VALID_DOMAIN = /^[a-zA-Z0-9]{1,61}[a-zA-Z0-9](?:\.[a-zA-Z]{2,})+$/.freeze

    PARAMS_TO_BE_CLEANED = %i[sidebar_tags suggested_tags suggested_users].freeze

    attr_reader :errors

    def self.call(configs)
      new(configs).call
    end

    def initialize(configs)
      @configs = configs
      @success = false
    end

    def call
      clean_up_params

      @errors = []
      upsert_configs
      return self if @errors.any?

      @success = true
      after_upsert_tasks
      self
    end

    def success?
      @success
    end

    def upsert_configs
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
      rescue ActiveRecord::RecordInvalid => e
        @errors << e.message
        next
      end
    end

    def after_upsert_tasks
      create_tags_if_not_created
    end

    def clean_up_params
      PARAMS_TO_BE_CLEANED.each do |param|
        @configs[param] = @configs[param]&.downcase&.delete(" ") if @configs[param]
      end
      @configs[:credit_prices_in_cents]&.transform_values!(&:to_i)
    end

    def update_enabled_auth_providers(value)
      enabled_providers = value.split(",").filter_map do |entry|
        entry unless invalid_provider_entry(entry)
      end
      SiteConfig.public_send("authentication_providers=", enabled_providers) unless
        email_login_disabled_with_one_or_less_auth_providers(enabled_providers)
    end

    def email_login_disabled_with_one_or_less_auth_providers(enabled_providers)
      !SiteConfig.allow_email_password_login && enabled_providers.count <= 1
    end

    def invalid_provider_entry(entry)
      entry.blank? || Authentication::Providers.available.map(&:to_s).exclude?(entry) ||
        provider_keys_missing(entry)
    end

    def provider_keys_missing(entry)
      SiteConfig.public_send("#{entry}_key").blank? || SiteConfig.public_send("#{entry}_secret").blank?
    end

    def create_tags_if_not_created
      # Bulk create tags if they should exist.
      # This is an acts-as-taggable-on as used on saving of an Article, etc.
      return unless (@configs.keys & %w[suggested_tags sidebar_tags]).any?

      Tag.find_or_create_all_with_like_by_name(SiteConfig.suggested_tags + SiteConfig.sidebar_tags)
    end
  end
end
