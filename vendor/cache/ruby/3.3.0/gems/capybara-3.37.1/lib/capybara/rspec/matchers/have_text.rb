# frozen_string_literal: true

require 'capybara/rspec/matchers/base'

module Capybara
  module RSpecMatchers
    module Matchers
      class HaveText < CountableWrappedElementMatcher
        def element_matches?(el)
          el.assert_text(*@args, **@kw_args)
        end

        def element_does_not_match?(el)
          el.assert_no_text(*@args, **@kw_args)
        end

        def description
          "have text #{format(text)}"
        end

        def format(content)
          content.inspect
        end

      private

        def text
          @args[0].is_a?(Symbol) ? @args[1] : @args[0]
        end
      end
    end
  end
end
