module Captcha
  module Providers
    class Recaptcha
      def self.label
        "Google reCAPTCHA"
      end

      def self.enabled?
        Settings::Authentication.recaptcha_site_key.present? &&
          Settings::Authentication.recaptcha_secret_key.present?
      end

      def self.verify(context:, **)
        context.params["g-recaptcha-response"] &&
          context.__send__(:verify_recaptcha, secret_key: Settings::Authentication.recaptcha_secret_key)
      end

      def self.partial
        "shared/captcha/recaptcha"
      end

      def self.container_class
        "recaptcha-tag-container"
      end

      def self.error_key
        "recaptcha"
      end
    end
  end
end
