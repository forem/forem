# frozen_string_literal: true

module Capybara
  module Cuprite
    class Error < StandardError; end

    class ClientError < Error
      attr_reader :response

      def initialize(response)
        @response = response
        super()
      end
    end

    class InvalidSelector < ClientError
      def initialize(response, method, selector)
        super(response)
        @method = method
        @selector = selector
      end

      def message
        "Browser raised error trying to find #{@method}: #{@selector.inspect}"
      end
    end

    class MouseEventFailed < ClientError
      attr_reader :name, :selector, :position

      def initialize(*)
        super
        data = /\A\w+: (\w+), (.+?), ([\d.-]+), ([\d.-]+)/.match(@response)
        @name, @selector = data.values_at(1, 2)
        @position = data.values_at(3, 4).map(&:to_f)
      end

      def message
        "Firing a #{name} at coordinates [#{position.join(', ')}] failed. Cuprite detected " \
          "another element with CSS selector \"#{selector}\" at this position. " \
          "It may be overlapping the element you are trying to interact with. " \
          "If you don't care about overlapping elements, try using node.trigger(\"#{name}\")."
      end
    end

    class ObsoleteNode < ClientError
      attr_reader :node

      def initialize(node, response)
        @node = node
        super(response)
      end

      def message
        "The element you are trying to interact with is either not part of the DOM, or is " \
          "not currently visible on the page (perhaps display: none is set). " \
          "It is possible the element has been replaced by another element and you meant to interact with " \
          "the new element. If so you need to do a new find in order to get a reference to the " \
          "new element."
      end
    end
  end
end
