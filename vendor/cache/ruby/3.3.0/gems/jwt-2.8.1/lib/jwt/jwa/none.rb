# frozen_string_literal: true

module JWT
  module JWA
    module None
      module_function

      SUPPORTED = %w[none].freeze

      def sign(*)
        ''
      end

      def verify(*)
        true
      end
    end
  end
end
