# frozen_string_literal: true

require 'ast'
require 'set'
require 'i18n/tasks/scanners/local_ruby_parser'

module I18n::Tasks::Scanners
  class ErbAstProcessor
    include AST::Processor::Mixin
    def initialize
      super()
      @ruby_parser = LocalRubyParser.new(ignore_blocks: true)
      @comments = []
    end

    def process_and_extract_comments(ast)
      result = process(ast)
      [result, @comments]
    end

    def on_code(node)
      parsed, comments = @ruby_parser.parse(
        node.children[0],
        location: node.location
      )
      @comments.concat(comments)

      unless parsed.nil?
        parsed = parsed.updated(
          nil,
          parsed.children.map { |child| node?(child) ? process(child) : child }
        )
        node = node.updated(:send, parsed)
      end
      node
    end

    # @param node [::Parser::AST::Node]
    # @return [::Parser::AST::Node]
    def handler_missing(node)
      node = handle_comment(node)
      return if node.nil?

      node.updated(
        nil,
        node.children.map { |child| node?(child) ? process(child) : child }
      )
    end

    private

    # Convert ERB-comments to ::Parser::Source::Comment and skip processing node
    #
    # @param node Parser::AST::Node Potential comment node
    # @return Parser::AST::Node or nil
    def handle_comment(node)
      if node.type == :erb && node.children.size == 4 &&
         node.children[0]&.type == :indicator && node.children[0].children[0] == '#' &&
         node.children[2]&.type == :code

        # Do not continue parsing this node
        comment = node.children[2]
        @comments << ::Parser::Source::Comment.new(comment.location.expression)
        return
      end

      node
    end

    def node?(node)
      node.is_a?(::Parser::AST::Node)
    end
  end
end
