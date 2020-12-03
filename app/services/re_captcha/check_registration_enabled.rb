module ReCaptcha
  class CheckRegistrationEnabled
    def self.call
      new.call
    end

    def call
      # ReCaptcha::CheckEnabled.call without a user parameter will return `true`
      # if the ReCaptcha SiteConfig keys are configured, and `false` otherwise
      ReCaptcha::CheckEnabled.call && SiteConfig.require_captcha_for_email_password_registration
    end
  end
end
