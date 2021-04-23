# Helper method for controllers interacting with SiteConfig
module SettingsParams
  SPECIAL_PARAMS_TO_ADD = %w[
    credit_prices_in_cents
    email_addresses
    meta_keywords
  ].freeze

  def settings_params
    has_emails = params.dig(:site_config, :email_addresses).present?
    params[:site_config][:email_addresses][:default] = ApplicationConfig["DEFAULT_EMAIL"] if has_emails

    params.require(:site_config)&.permit(
      settings_keys.map(&:to_sym),
      social_media_handles: SiteConfig.social_media_handles.keys,
      email_addresses: SiteConfig.email_addresses.keys,
      meta_keywords: SiteConfig.meta_keywords.keys,
      credit_prices_in_cents: SiteConfig.credit_prices_in_cents.keys,
    )
  end

  private

  def settings_keys
    SiteConfig.keys + SPECIAL_PARAMS_TO_ADD
  end
end
