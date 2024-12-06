# frozen_string_literal: true

module Capybara
  module Queries
    class SiblingQuery < SelectorQuery
      # @api private
      def resolve_for(node, exact = nil)
        @sibling_node = node
        node.synchronize do
          scope = node.respond_to?(:session) ? node.session.current_scope : node.find(:xpath, '/*')
          match_results = super(scope, exact)
          siblings = node.find_xpath((XPath.preceding_sibling + XPath.following_sibling).to_s)
                         .map(&method(:to_element))
                         .select { |el| match_results.include?(el) }
          Capybara::Result.new(ordered_results(siblings), self)
        end
      end

      def description(applied = false) # rubocop:disable Style/OptionalBooleanParameter
        desc = super
        sibling_query = @sibling_node&.instance_variable_get(:@query)
        desc += " that is a sibling of #{sibling_query.description}" if sibling_query
        desc
      end
    end
  end
end
