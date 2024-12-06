# frozen_string_literal: true

require_relative 'error_message_formatter'

module Pundit
  module Matchers
    module Utils
      module AllActions
        # Error message formatter for `permit_all_actions` matcher.
        class PermittedActionsErrorFormatter
          include AllActions::ErrorMessageFormatter

          def initialize(matcher)
            @expected_kind = 'permitted'
            @opposite_kind = 'forbidden'
            @matcher = matcher
          end

          private

          attr_reader :matcher, :expected_kind, :opposite_kind
        end
      end
    end
  end
end
