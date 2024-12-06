# frozen_string_literal: true

module DerailedBenchmarks
  class AuthHelpers
    # Devise helper for authenticating requests
    # Setup adds necessarry test methods, user provides a sample user.
    # The authenticate method is called on every request when authentication is enabled
    class Devise < AuthHelper
      attr_writer :user

      # Include devise test helpers and turn on test mode
      # We need to do this on the class level
      def setup
        # self.class.instance_eval do
          require 'devise'
          require 'warden'
          extend ::Warden::Test::Helpers
          extend ::Devise::TestHelpers
          Warden.test_mode!
        # end
      end

      def user
        if @user
          @user = @user.call if @user.is_a?(Proc)
          @user
        else
          password = SecureRandom.hex
          @user = User.first_or_create!(email: "#{SecureRandom.hex}@example.com", password: password, password_confirmation: password)
        end
      end

      # Logs the user in, then call the parent app
      def call(env)
        login_as(user)
        app.call(env)
      end
    end
  end
end

