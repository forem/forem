# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      module Capybara
        # @!parse
        #   # Checks if there is a more specific finder offered by Capybara.
        #   #
        #   # @example
        #   #   # bad
        #   #   find('#some-id')
        #   #   find('[visible][id=some-id]')
        #   #
        #   #   # good
        #   #   find_by_id('some-id')
        #   #   find_by_id('some-id', visible: true)
        #   #
        #   class SpecificFinders < ::RuboCop::Cop::Base; end
        SpecificFinders = ::RuboCop::Cop::Capybara::SpecificFinders
      end
    end
  end
end
