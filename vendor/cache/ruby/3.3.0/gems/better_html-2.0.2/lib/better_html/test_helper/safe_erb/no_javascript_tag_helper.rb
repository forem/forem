# frozen_string_literal: true

require_relative "base"
require "better_html/test_helper/ruby_node"

module BetterHtml
  module TestHelper
    module SafeErb
      class NoJavascriptTagHelper < Base
        def validate
          no_javascript_tag_helper(ast)
        end

        private

        def no_javascript_tag_helper(node)
          erb_nodes(node).each do |erb_node, indicator_node, code_node|
            indicator = indicator_node&.loc&.source
            next if indicator == "#" || indicator == "%"

            source = code_node.loc.source

            ruby_node = begin
              RubyNode.parse(source)
            rescue ::Parser::SyntaxError
              nil
            end
            next unless ruby_node

            ruby_node.descendants(:send, :csend).each do |send_node|
              next unless send_node.method_name?(:javascript_tag)

              add_error(
                "'javascript_tag do' syntax is deprecated; use inline <script> instead",
                location: erb_node.loc,
              )
            end
          end
        end
      end
    end
  end
end
