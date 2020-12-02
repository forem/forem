module ReCaptcha
  class CheckRegistrationEnabled
    def self.call
      new.call
    end

    def call
      # ReCaptcha::CheckEnabled.call without passing in a user as parameter will
      # always return `true` if the SiteConfig keys are configured correctly
      ReCaptcha::CheckEnabled.call && SiteConfig.require_captcha_for_email_password_registration
    end
  end
end
