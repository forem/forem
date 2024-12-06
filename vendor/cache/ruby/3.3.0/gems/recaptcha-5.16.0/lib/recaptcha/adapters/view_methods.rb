# frozen_string_literal: true

module Recaptcha
  module Adapters
    module ViewMethods
      # Renders a [reCAPTCHA v3](https://developers.google.com/recaptcha/docs/v3) script and (by
      # default) a hidden input to submit the response token. You can also call the functions
      # directly if you prefer. You can use
      # `Recaptcha::Helpers.recaptcha_v3_execute_function_name(action)` to get the name of the
      # function to call.
      def recaptcha_v3(options = {})
        ::Recaptcha::Helpers.recaptcha_v3(options)
      end

      # Renders a reCAPTCHA [v2 Checkbox](https://developers.google.com/recaptcha/docs/display) widget
      def recaptcha_tags(options = {})
        ::Recaptcha::Helpers.recaptcha_tags(options)
      end

      # Renders a reCAPTCHA v2 [Invisible reCAPTCHA](https://developers.google.com/recaptcha/docs/invisible)
      def invisible_recaptcha_tags(options = {})
        ::Recaptcha::Helpers.invisible_recaptcha_tags(options)
      end
    end
  end
end
