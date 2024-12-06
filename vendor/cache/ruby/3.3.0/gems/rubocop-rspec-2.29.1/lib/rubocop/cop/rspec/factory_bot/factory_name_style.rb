# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      module FactoryBot
        # @!parse
        #   # Checks for name style for argument of FactoryBot::Syntax::Methods.
        #   #
        #   # @example EnforcedStyle: symbol (default)
        #   #   # bad
        #   #   create('user')
        #   #   build "user", username: "NAME"
        #   #
        #   #   # good
        #   #   create(:user)
        #   #   build :user, username: "NAME"
        #   #
        #   # @example EnforcedStyle: string
        #   #   # bad
        #   #   create(:user)
        #   #   build :user, username: "NAME"
        #   #
        #   #   # good
        #   #   create('user')
        #   #   build "user", username: "NAME"
        #   #
        #   class FactoryNameStyle < ::RuboCop::Cop::Base; end
        FactoryNameStyle = ::RuboCop::Cop::FactoryBot::FactoryNameStyle
      end
    end
  end
end
