module ReCaptcha
  class CheckRegistrationEnabled
    def self.call
      # ReCaptcha::CheckEnabled.call without a user parameter will return `true`
      # if the ReCaptcha Settings::General keys are configured, and `false` otherwise
      ReCaptcha::CheckEnabled.call &&
        Settings::Authentication.require_captcha_for_email_password_registration
    end
  end
end
