# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      module Capybara
        # @!parse
        #   # Checks that no expectations are set on Capybara's `current_path`.
        #   #
        #   # The
        #   # https://www.rubydoc.info/github/teamcapybara/capybara/master/Capybara/RSpecMatchers#have_current_path-instance_method[`have_current_path` matcher]
        #   # should be used on `page` to set expectations on Capybara's
        #   # current path, since it uses
        #   # https://github.com/teamcapybara/capybara/blob/master/README.md#asynchronous-javascript-ajax-and-friends[Capybara's waiting functionality]
        #   # which ensures that preceding actions (like `click_link`) have
        #   # completed.
        #   #
        #   # This cop does not support autocorrection in some cases.
        #   #
        #   # @example
        #   #   # bad
        #   #   expect(current_path).to eq('/callback')
        #   #
        #   #   # good
        #   #   expect(page).to have_current_path('/callback')
        #   #
        #   #   # bad (does not support autocorrection)
        #   #   expect(page.current_path).to match(variable)
        #   #
        #   #   # good
        #   #   expect(page).to have_current_path('/callback')
        #   #
        #   class CurrentPathExpectation < ::RuboCop::Cop::Base; end
        CurrentPathExpectation =
          ::RuboCop::Cop::Capybara::CurrentPathExpectation
      end
    end
  end
end
