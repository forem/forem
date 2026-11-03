module Captcha
  PROVIDERS = {
    "recaptcha" => Providers::Recaptcha,
    "turnstile" => Providers::Turnstile,
    "hcaptcha" => Providers::HCaptcha
  }.freeze

  def self.provider
    PROVIDERS.fetch(Settings::Authentication.captcha_provider)
  end
end
