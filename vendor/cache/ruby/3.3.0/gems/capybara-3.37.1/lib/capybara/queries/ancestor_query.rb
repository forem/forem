# frozen_string_literal: true

module Capybara
  module Queries
    class AncestorQuery < Capybara::Queries::SelectorQuery
      # @api private
      def resolve_for(node, exact = nil)
        @child_node = node

        node.synchronize do
          scope = node.respond_to?(:session) ? node.session.current_scope : node.find(:xpath, '/*')
          match_results = super(scope, exact)
          ancestors = node.find_xpath(XPath.ancestor.to_s)
                          .map(&method(:to_element))
                          .select { |el| match_results.include?(el) }
          Capybara::Result.new(ordered_results(ancestors), self)
        end
      end

      def description(applied = false) # rubocop:disable Style/OptionalBooleanParameter
        child_query = @child_node&.instance_variable_get(:@query)
        desc = super
        desc += " that is an ancestor of #{child_query.description}" if child_query
        desc
      end
    end
  end
end
