# frozen_string_literal: true

module Recaptcha
  module Adapters
    module ControllerMethods
      private

      # Your private API can be specified in the +options+ hash or preferably
      # using the Configuration.
      def verify_recaptcha(options = {})
        options = {model: options} unless options.is_a? Hash
        return true if Recaptcha.skip_env?(options[:env])

        model = options[:model]
        attribute = options.fetch(:attribute, :base)
        recaptcha_response = options[:response] || recaptcha_response_token(options[:action])

        begin
          verified = if Recaptcha.invalid_response?(recaptcha_response)
            false
          else
            unless options[:skip_remote_ip]
              remoteip = (request.respond_to?(:remote_ip) && request.remote_ip) || (env && env['REMOTE_ADDR'])
              options = options.merge(remote_ip: remoteip.to_s) if remoteip
            end

            success, @_recaptcha_reply =
              Recaptcha.verify_via_api_call(recaptcha_response, options.merge(with_reply: true))
            success
          end

          if verified
            flash.delete(:recaptcha_error) if recaptcha_flash_supported? && !model
            true
          else
            recaptcha_error(
              model,
              attribute,
              options.fetch(:message) { Recaptcha::Helpers.to_error_message(:verification_failed) }
            )
            false
          end
        rescue Timeout::Error
          if Recaptcha.configuration.handle_timeouts_gracefully
            recaptcha_error(
              model,
              attribute,
              options.fetch(:message) { Recaptcha::Helpers.to_error_message(:recaptcha_unreachable) }
            )
            false
          else
            raise RecaptchaError, 'Recaptcha unreachable.'
          end
        rescue StandardError => e
          raise RecaptchaError, e.message, e.backtrace
        end
      end

      def verify_recaptcha!(options = {})
        verify_recaptcha(options) || raise(VerifyError)
      end

      def recaptcha_reply
        @_recaptcha_reply if defined?(@_recaptcha_reply)
      end

      def recaptcha_error(model, attribute, message)
        if model
          model.errors.add(attribute, message)
        elsif recaptcha_flash_supported?
          flash[:recaptcha_error] = message
        end
      end

      def recaptcha_flash_supported?
        request.respond_to?(:format) && request.format == :html && respond_to?(:flash)
      end

      # Extracts response token from params. params['g-recaptcha-response-data'] for recaptcha_v3 or
      # params['g-recaptcha-response'] for recaptcha_tags and invisible_recaptcha_tags and should
      # either be a string or a hash with the action name(s) as keys. If it is a hash, then `action`
      # is used as the key.
      # @return [String] A response token if one was passed in the params; otherwise, `''`
      def recaptcha_response_token(action = nil)
        response_param = params['g-recaptcha-response-data'] || params['g-recaptcha-response']
        response_param = response_param[action] if action && response_param.respond_to?(:key?)

        if response_param.is_a?(String)
          response_param
        else
          ''
        end
      end
    end
  end
end
