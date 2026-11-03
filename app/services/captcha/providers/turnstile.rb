module Captcha
  module Providers
    class Turnstile
      def self.label
        "Cloudflare Turnstile"
      end

      def self.enabled?
        true
      end

      def self.verify(context:, **)
        ::Turnstile::Verify.call(token: context.params["cf-turnstile-response"], hostname: context.request.host)
      end

      def self.partial
        "shared/captcha/turnstile"
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
