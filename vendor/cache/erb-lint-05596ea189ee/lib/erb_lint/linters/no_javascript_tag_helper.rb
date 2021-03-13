# frozen_string_literal: true

require 'better_html'
require 'better_html/ast/node'
require 'better_html/test_helper/ruby_node'
require 'erb_lint/utils/block_map'
require 'erb_lint/utils/ruby_to_erb'

module ERBLint
  module Linters
    class NoJavascriptTagHelper < Linter
      include LinterRegistry

      class ConfigSchema < LinterConfig
        property :correction_style, converts: :to_sym, accepts: [:cdata, :plain], default: :cdata
      end
      self.config_schema = ConfigSchema

      def run(processed_source)
        parser = processed_source.parser
        parser.ast.descendants(:erb).each do |erb_node|
          indicator_node, _, code_node, _ = *erb_node
          indicator = indicator_node&.loc&.source
          next if indicator == '#'
          source = code_node.loc.source

          ruby_node =
            begin
              BetterHtml::TestHelper::RubyNode.parse(source)
            rescue ::Parser::SyntaxError
              nil
            end
          next unless ruby_node
          send_node = ruby_node.descendants(:send).first
          next unless send_node&.method_name?(:javascript_tag)

          add_offense(
            erb_node.loc,
            "Avoid using 'javascript_tag do' as it confuses tests "\
            "that validate html, use inline <script> instead",
            [erb_node, send_node]
          )
        end
      end

      def autocorrect(processed_source, offense)
        lambda do |corrector|
          correct_offense(processed_source, offense, corrector)
        end
      end

      private

      def correct_offense(processed_source, offense, corrector)
        erb_node, send_node = *offense.context
        block_map = Utils::BlockMap.new(processed_source)
        nodes = block_map.find_connected_nodes(erb_node) || [erb_node]
        return unless (1..2).cover?(nodes.size)

        begin_node, end_node = nodes

        argument_nodes = send_node.arguments
        return unless (0..2).cover?(argument_nodes.size)

        script_content = unless argument_nodes.first&.type?(:hash)
          Utils::RubyToERB.ruby_to_erb(argument_nodes.first, '==')
        end
        arguments = if argument_nodes.last&.type?(:hash)
          ' ' + Utils::RubyToERB.html_options_to_tag_attributes(argument_nodes.last)
        end

        return if end_node && script_content

        if end_node
          begin_content = "<script#{arguments}>"
          begin_content += "\n//<![CDATA[\n" if @config.correction_style == :cdata
          corrector.replace(begin_node.loc, begin_content)
          end_content = "</script>"
          end_content = "\n//]]>\n" + end_content if @config.correction_style == :cdata
          corrector.replace(end_node.loc, end_content)
        elsif script_content
          script_content = "\n//<![CDATA[\n#{script_content}\n//]]>\n" if @config.correction_style == :cdata
          corrector.replace(begin_node.loc,
            "<script#{arguments}>#{script_content}</script>")
        end
      rescue Utils::RubyToERB::Error, Utils::BlockMap::ParseError
        nil
      end
    end
  end
end
