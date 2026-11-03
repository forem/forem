module Captcha
  PROVIDERS = {
    "recaptcha" => Providers::Recaptcha,
    "turnstile" => Providers::Turnstile
  }.freeze

  def self.provider
    PROVIDERS.fetch(Settings::Authentication.captcha_provider)
  end
end
