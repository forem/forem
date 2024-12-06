# frozen_string_literal: true

module Capybara
  module Selenium
    module IsDisplayed
      def commands(command)
        case command
        when :is_element_displayed
          [:get, 'session/:session_id/element/:id/displayed']
        else
          super
        end
      end
    end
  end
end
