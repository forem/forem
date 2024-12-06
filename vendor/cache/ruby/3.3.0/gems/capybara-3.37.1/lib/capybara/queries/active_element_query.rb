# frozen_string_literal: true

module Capybara
  # @api private
  module Queries
    class ActiveElementQuery < BaseQuery
      def initialize(**options)
        @options = options
        super(@options)
      end

      def resolve_for(session)
        node = session.driver.active_element
        [Capybara::Node::Element.new(session, node, nil, self)]
      end
    end
  end
end
