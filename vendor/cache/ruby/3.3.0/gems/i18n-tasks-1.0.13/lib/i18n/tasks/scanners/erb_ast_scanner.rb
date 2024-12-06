# frozen_string_literal: true

require 'i18n/tasks/scanners/ruby_ast_scanner'
require 'i18n/tasks/scanners/erb_ast_processor'
require 'better_html/errors'
require 'better_html/parser'

module I18n::Tasks::Scanners
  # Scan for I18n.translate calls in ERB-file better-html and ASTs
  class ErbAstScanner < RubyAstScanner
    def initialize(**args)
      super(**args)
      @erb_ast_processor = ErbAstProcessor.new
    end

    private

    # Parse file on path and returns AST and comments.
    #
    # @param path Path to file to parse
    # @return [{Parser::AST::Node}, [Parser::Source::Comment]]
    def path_to_ast_and_comments(path)
      parser = BetterHtml::Parser.new(make_buffer(path))
      ast = convert_better_html(parser.ast)
      @erb_ast_processor.process_and_extract_comments(ast)
    end

    # Convert BetterHtml nodes to Parser::AST::Node
    #
    # @param node BetterHtml::Parser::AST::Node
    # @return Parser::AST::Node
    def convert_better_html(node)
      definition = Parser::Source::Map::Definition.new(
        node.location.begin,
        node.location.begin,
        node.location.begin,
        node.location.end
      )
      Parser::AST::Node.new(
        node.type,
        node.children.map { |child| child.is_a?(BetterHtml::AST::Node) ? convert_better_html(child) : child },
        {
          location: definition
        }
      )
    end
  end
end
