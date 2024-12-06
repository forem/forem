# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      module FactoryBot
        # @!parse
        #   # Use a consistent style for parentheses in factory bot calls.
        #   #
        #   # @example
        #   #
        #   #   # bad
        #   #   create :user
        #   #   build(:user)
        #   #   create(:login)
        #   #   create :login
        #   #
        #   # @example `EnforcedStyle: require_parentheses` (default)
        #   #
        #   #   # good
        #   #   create(:user)
        #   #   create(:user)
        #   #   create(:login)
        #   #   build(:login)
        #   #
        #   # @example `EnforcedStyle: omit_parentheses`
        #   #
        #   #   # good
        #   #   create :user
        #   #   build :user
        #   #   create :login
        #   #   create :login
        #   #
        #   #   # also good
        #   #   # when method name and first argument are not on same line
        #   #   create(
        #   #     :user
        #   #   )
        #   #   build(
        #   #     :user,
        #   #     name: 'foo'
        #   #   )
        #   #
        #   class ConsistentParenthesesStyle < ::RuboCop::Cop::Base; end
        ConsistentParenthesesStyle =
          ::RuboCop::Cop::FactoryBot::ConsistentParenthesesStyle
      end
    end
  end
end
