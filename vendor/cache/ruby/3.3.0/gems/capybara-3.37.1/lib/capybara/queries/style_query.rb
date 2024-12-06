# frozen_string_literal: true

module Capybara
  # @api private
  module Queries
    class StyleQuery < BaseQuery
      def initialize(expected_styles, session_options:, **options)
        @expected_styles = stringify_keys(expected_styles)
        @options = options
        @actual_styles = {}
        super(@options)
        self.session_options = session_options

        assert_valid_keys
      end

      def resolves_for?(node)
        @node = node
        @actual_styles = node.style(*@expected_styles.keys)
        @expected_styles.all? do |style, value|
          if value.is_a? Regexp
            value.match? @actual_styles[style]
          else
            @actual_styles[style] == value
          end
        end
      end

      def failure_message
        +"Expected node to have styles #{@expected_styles.inspect}. " \
         "Actual styles were #{@actual_styles.inspect}"
      end

    private

      def stringify_keys(hsh)
        hsh.transform_keys(&:to_s)
      end

      def valid_keys
        %i[wait]
      end
    end
  end
end
