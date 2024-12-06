# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      module FactoryBot
        # @!parse
        #   # Always declare attribute values as blocks.
        #   #
        #   # @example
        #   #   # bad
        #   #   kind [:active, :rejected].sample
        #   #
        #   #   # good
        #   #   kind { [:active, :rejected].sample }
        #   #
        #   #   # bad
        #   #   closed_at 1.day.from_now
        #   #
        #   #   # good
        #   #   closed_at { 1.day.from_now }
        #   #
        #   #   # bad
        #   #   count 1
        #   #
        #   #   # good
        #   #   count { 1 }
        #   #
        #   class AttributeDefinedStatically < ::RuboCop::Cop::Base; end
        AttributeDefinedStatically =
          ::RuboCop::Cop::FactoryBot::AttributeDefinedStatically
      end
    end
  end
end
