module Captcha
  class CheckRegistrationEnabled
    def self.call
      Captcha::CheckEnabled.call && Settings::Authentication.require_captcha_for_email_password_registration
    end
  end
end
