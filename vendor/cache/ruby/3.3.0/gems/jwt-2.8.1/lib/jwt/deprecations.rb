# frozen_string_literal: true

module JWT
  # Deprecations module to handle deprecation warnings in the gem
  module Deprecations
    class << self
      def warning(message)
        case JWT.configuration.deprecation_warnings
        when :warn
          warn("[DEPRECATION WARNING] #{message}")
        when :once
          return if record_warned(message)

          warn("[DEPRECATION WARNING] #{message}")
        end
      end

      private

      def record_warned(message)
        @warned ||= []
        return true if @warned.include?(message)

        @warned << message
        false
      end
    end
  end
end
