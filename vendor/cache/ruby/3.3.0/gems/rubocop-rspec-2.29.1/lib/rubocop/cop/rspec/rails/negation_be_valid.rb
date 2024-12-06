# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      module Rails
        # @!parse
        #   # Enforces use of `be_invalid` or `not_to` for negated be_valid.
        #   #
        #   # @safety
        #   #   This cop is unsafe because it cannot guarantee that
        #   #   the test target is an instance of `ActiveModel::Validations``.
        #   #
        #   # @example EnforcedStyle: not_to (default)
        #   #   # bad
        #   #   expect(foo).to be_invalid
        #   #
        #   #   # good
        #   #   expect(foo).not_to be_valid
        #   #
        #   #   # good (with method chain)
        #   #   expect(foo).to be_invalid.and be_odd
        #   #
        #   # @example EnforcedStyle: be_invalid
        #   #   # bad
        #   #   expect(foo).not_to be_valid
        #   #
        #   #   # good
        #   #   expect(foo).to be_invalid
        #   #
        #   #   # good (with method chain)
        #   #   expect(foo).to be_invalid.or be_even
        #   #
        #   class NegationBeValid < RuboCop::Cop::RSpec::Base; end
        NegationBeValid = ::RuboCop::Cop::RSpecRails::NegationBeValid
      end
    end
  end
end
