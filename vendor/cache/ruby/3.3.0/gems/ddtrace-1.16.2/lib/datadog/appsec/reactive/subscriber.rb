# frozen_string_literal: true

module Datadog
  module AppSec
    module Reactive
      # Reactive Engine subscriber
      class Subscriber
        def initialize(&block)
          @block = block
          freeze
        end

        def call(*args)
          @block.call(*args)
        end
      end
    end
  end
end
