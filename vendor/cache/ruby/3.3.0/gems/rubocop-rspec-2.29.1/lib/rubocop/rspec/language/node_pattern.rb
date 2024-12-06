# frozen_string_literal: true

module RuboCop
  module RSpec
    module Language
      # Helper methods to detect RSpec DSL used with send and block
      # @deprecated Prefer using Node Pattern directly
      #   Use `'(block (send nil? #Example.all ...) ...)'` instead of
      #   `block_pattern('#Example.all')`
      module NodePattern
        # @deprecated Prefer using Node Pattern directly
        def send_pattern(string)
          deprecation_warning __method__
          "(send #rspec? #{string} ...)"
        end

        # @deprecated Prefer using Node Pattern directly
        def block_pattern(string)
          deprecation_warning __method__
          "(block #{send_pattern(string)} ...)"
        end

        # @deprecated Prefer using Node Pattern directly
        def numblock_pattern(string)
          deprecation_warning __method__
          "(numblock #{send_pattern(string)} ...)"
        end

        # @deprecated Prefer using Node Pattern directly
        def block_or_numblock_pattern(string)
          deprecation_warning __method__
          "{#{block_pattern(string)} #{numblock_pattern(string)}}"
        end

        private

        def deprecation_warning(method)
          # Only warn in derived extensions' specs
          return unless defined?(::RSpec)

          Kernel.warn <<~MESSAGE, uplevel: 2
            Usage of #{method} is deprecated. Use node pattern explicitly.
          MESSAGE
        end
      end
    end
  end
end
