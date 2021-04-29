# Helper method for controllers interacting with Settings::General
module SettingsParams
  SPECIAL_PARAMS_TO_ADD = %w[
    credit_prices_in_cents
    email_addresses
    meta_keywords
  ].freeze

  def settings_params
    has_emails = params.dig(:settings_general, :email_addresses).present?
    params[:settings_general][:email_addresses][:default] = ApplicationConfig["DEFAULT_EMAIL"] if has_emails

    params.require(:settings_general)&.permit(
      settings_keys.map(&:to_sym),
      social_media_handles: Settings::General.social_media_handles.keys,
      email_addresses: Settings::General.email_addresses.keys,
      meta_keywords: Settings::General.meta_keywords.keys,
      credit_prices_in_cents: Settings::General.credit_prices_in_cents.keys,
    )
  end

  private

  def settings_keys
    Settings::General.keys + SPECIAL_PARAMS_TO_ADD
  end
end
