# frozen_string_literal: true

require_relative 'decode_configuration'
require_relative 'jwk_configuration'

module JWT
  module Configuration
    class Container
      attr_accessor :decode, :jwk, :strict_base64_decoding
      attr_reader :deprecation_warnings

      def initialize
        reset!
      end

      def reset!
        @decode                 = DecodeConfiguration.new
        @jwk                    = JwkConfiguration.new
        @strict_base64_decoding = false

        self.deprecation_warnings = :once
      end

      DEPRECATION_WARNINGS_VALUES = %i[once warn silent].freeze
      def deprecation_warnings=(value)
        raise ArgumentError, "Invalid deprecation_warnings value #{value}. Supported values: #{DEPRECATION_WARNINGS_VALUES}" unless DEPRECATION_WARNINGS_VALUES.include?(value)

        @deprecation_warnings = value
      end
    end
  end
end
