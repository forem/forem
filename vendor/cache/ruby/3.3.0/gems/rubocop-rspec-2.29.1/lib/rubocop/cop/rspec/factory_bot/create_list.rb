# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      module FactoryBot
        # @!parse
        #   # Checks for create_list usage.
        #   #
        #   # This cop can be configured using the `EnforcedStyle` option
        #   #
        #   # @example `EnforcedStyle: create_list` (default)
        #   #   # bad
        #   #   3.times { create :user }
        #   #
        #   #   # good
        #   #   create_list :user, 3
        #   #
        #   #   # bad
        #   #   3.times { create :user, age: 18 }
        #   #
        #   #   # good - index is used to alter the created models attributes
        #   #   3.times { |n| create :user, age: n }
        #   #
        #   #   # good - contains a method call, may return different values
        #   #   3.times { create :user, age: rand }
        #   #
        #   # @example `EnforcedStyle: n_times`
        #   #   # bad
        #   #   create_list :user, 3
        #   #
        #   #   # good
        #   #   3.times { create :user }
        #   #
        #   class CreateList < ::RuboCop::Cop::Base; end
        CreateList = ::RuboCop::Cop::FactoryBot::CreateList
      end
    end
  end
end
