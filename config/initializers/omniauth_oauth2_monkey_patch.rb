# frozen_string_literal: true

require "omniauth/strategies/oauth2"

module OmniAuth
  module Strategies
    class OAuth2
      # Forem patched: The `omniauth-oauth2` gem currently breaks with `NoMethodError: undefined method expired? for nil`
      # if the returned token authorization exchange fails silently and yields a nil access context. 
      # By trapping it here and invoking `fail!`, we allow OmniAuth to gracefully kick the user
      # to the Failure endpoint with a flash message rather than throwing a hard 500 error.
      # See: https://github.com/omniauth/omniauth-oauth2/issues/131
      
      alias_method :original_callback_phase, :callback_phase

      def callback_phase
        original_callback_phase
      rescue NoMethodError => e
        if e.message.include?("expired?' for nil")
          fail!(:invalid_credentials, StandardError.new("access_token was nil when checking expiration"))
        else
          raise e
        end
      end
    end
  end
end
