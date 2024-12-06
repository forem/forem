# frozen_string_literal: true

module Capybara
  module RSpecMatchers
    module Matchers
      class BecomeClosed
        def initialize(options)
          @options = options
        end

        def matches?(window)
          @window = window
          @wait_time = Capybara::Queries::BaseQuery.wait(@options, window.session.config.default_max_wait_time)
          timer = Capybara::Helpers.timer(expire_in: @wait_time)
          while window.exists?
            return false if timer.expired?

            sleep 0.01
          end
          true
        end

        def failure_message
          "expected #{@window.inspect} to become closed after #{@wait_time} seconds"
        end

        def failure_message_when_negated
          "expected #{@window.inspect} not to become closed after #{@wait_time} seconds"
        end
      end
    end
  end
end
