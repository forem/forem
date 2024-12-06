# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      module Rails
        # @!parse
        #   # Prefer to travel in `before` rather than `around`.
        #   #
        #   # @safety
        #   #   This cop is unsafe because the automatic `travel_back` is only
        #   #   run on test cases that are considered as Rails related.
        #   #
        #   #   And also, this cop's autocorrection is unsafe because the order
        #   #   of execution will change if other steps exist before traveling
        #   #   in `around`.
        #   #
        #   # @example
        #   #   # bad
        #   #   around do |example|
        #   #     freeze_time do
        #   #       example.run
        #   #     end
        #   #   end
        #   #
        #   #   # good
        #   #   before { freeze_time }
        #   #
        #   class TravelAround < RuboCop::Cop::RSpec::Base; end
        TravelAround = ::RuboCop::Cop::RSpecRails::TravelAround
      end
    end
  end
end
