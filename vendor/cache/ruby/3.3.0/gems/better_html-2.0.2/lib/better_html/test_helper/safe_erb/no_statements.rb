# frozen_string_literal: true

require_relative "base"

module BetterHtml
  module TestHelper
    module SafeErb
      class NoStatements < Base
        def validate
          script_tags.each do |tag, content_node|
            no_statements(content_node) unless content_node.present? && tag.attributes["type"]&.value == "text/html"
          end

          if @parser.template_language == :javascript
            @parser.nodes_with_type(:text).each do |node|
              no_statements(node)
            end
          end

          @parser.nodes_with_type(:cdata, :comment).each do |node|
            no_statements(node)
          end
        end

        private

        def no_statements(node)
          erb_nodes(node).each do |erb_node, indicator_node, code_node|
            next unless indicator_node.nil?

            source = code_node.loc.source

            next if /\A\s*end/m.match?(source)

            add_error(
              "erb statement not allowed here; did you mean '<%=' ?",
              location: erb_node.loc,
            )
          end
        end
      end
    end
  end
end
