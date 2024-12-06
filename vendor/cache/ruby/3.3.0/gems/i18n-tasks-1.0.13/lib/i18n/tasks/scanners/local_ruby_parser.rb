# frozen_string_literal: true

require 'parser/current'

module I18n::Tasks::Scanners
  class LocalRubyParser
    # ignore_blocks feature inspired by shopify/better-html
    # https://github.com/Shopify/better-html/blob/087943ffd2a5877fa977d71532010b0c91239519/lib/better_html/test_helper/ruby_node.rb#L24
    BLOCK_EXPR = /\s*((\s+|\))do|\{)(\s*\|[^|]*\|)?\s*\Z/.freeze

    def initialize(ignore_blocks: false)
      @parser = ::Parser::CurrentRuby.new
      @ignore_blocks = ignore_blocks
    end

    # Parse string and normalize location
    def parse(source, location: nil)
      buffer = ::Parser::Source::Buffer.new('(string)')
      buffer.source = if @ignore_blocks
                        source.sub(BLOCK_EXPR, '')
                      else
                        source
                      end

      @parser.reset
      ast, comments = @parser.parse_with_comments(buffer)
      ast = normalize_location(ast, location)
      comments = comments.map { |comment| normalize_comment_location(comment, location) }
      [ast, comments]
    end

    # Normalize location for all parsed nodes

    # @param node {Parser::AST::Node} Node in parsed code
    # @param location {Parser::Source::Map} Global location for the parsed string
    # @return {Parser::AST::Node}
    def normalize_location(node, location)
      return node.map { |child| normalize_location(child, location) } if node.is_a?(Array)

      return node unless node.is_a?(::Parser::AST::Node)

      node.updated(
        nil,
        node.children.map { |child| normalize_location(child, location) },
        { location: updated_location(location, node.location) }
      )
    end

    # Calculate location relative to a global location
    #
    # @param global_location {Parser::Source::Map} Global location where the code was parsed
    # @param local_location {Parser::Source::Map} Local location in the parsed string
    # @return {Parser::Source::Map}
    def updated_location(global_location, local_location)
      return global_location if local_location.expression.nil?

      range = ::Parser::Source::Range.new(
        global_location.expression.source_buffer,
        global_location.expression.to_range.begin + local_location.expression.to_range.begin,
        global_location.expression.to_range.begin + local_location.expression.to_range.end
      )

      ::Parser::Source::Map::Definition.new(
        range.begin,
        range.begin,
        range.begin,
        range.end
      )
    end

    # Normalize location for comment
    #
    # @param comment {Parser::Source::Comment} A comment with local location
    # @param location {Parser::Source::Map} Global location for the parsed string
    # @return {Parser::Source::Comment}
    def normalize_comment_location(comment, location)
      range = ::Parser::Source::Range.new(
        location.expression.source_buffer,
        location.expression.to_range.begin + comment.location.expression.to_range.begin,
        location.expression.to_range.begin + comment.location.expression.to_range.end
      )
      ::Parser::Source::Comment.new(range)
    end
  end
end
