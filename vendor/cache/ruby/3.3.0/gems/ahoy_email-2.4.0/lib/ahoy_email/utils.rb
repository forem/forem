module AhoyEmail
  class Utils
    OPTION_KEYS = {
      message: %i(message mailer user extra),
      utm_params: %i(utm_source utm_medium utm_term utm_content utm_campaign html5),
      click: %i(campaign url_options unsubscribe_links html5)
    }

    class << self
      def signature(token:, campaign:, url:, secret_token: nil)
        secret_token ||= secret_tokens.first

        # encode and join with a character outside encoding
        data = [token, campaign, url].map { |v| Base64.strict_encode64(v.to_s) }.join("|")

        Base64.urlsafe_encode64(OpenSSL::HMAC.digest("SHA256", secret_token, data), padding: false)
      end

      def signature_verified?(legacy:, token:, campaign:, url:, signature:)
        secret_tokens.any? do |secret_token|
          expected_signature =
            if legacy
              OpenSSL::HMAC.hexdigest("SHA1", secret_token, url)
            else
              signature(token: token, campaign: campaign, url: url, secret_token: secret_token)
            end

          ActiveSupport::SecurityUtils.secure_compare(signature, expected_signature)
        end
      end

      def publish(name, event)
        method_name = "track_#{name}"
        AhoyEmail.subscribers.each do |subscriber|
          subscriber = subscriber.new if subscriber.is_a?(Class)
          if subscriber.respond_to?(method_name)
            subscriber.send(method_name, event.dup)
          elsif name == :click && subscriber.respond_to?(:click)
            # legacy
            subscriber.send(:click, event.dup)
          end
        end
      end

      def secret_tokens
        Array(AhoyEmail.secret_token || (raise "Secret token is empty"))
      end
    end
  end
end
