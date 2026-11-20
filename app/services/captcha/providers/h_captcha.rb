module Captcha
  module Providers
    class HCaptcha
      def self.label
        "hCaptcha"
      end

      def self.enabled?
        true
      end

      def self.verify(context:, **)
        ::HCaptcha::Verify.call(token: context.params["h-captcha-response"])
      end

      def self.partial
        "shared/captcha/hcaptcha"
      end

      def self.container_class
        "captcha-tag-container"
      end

      def self.error_key
        "captcha"
      end
    end
  end
end
