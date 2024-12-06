# frozen_string_literal: true

require "better_html/parser"
require "parser/current"

module BetterHtml
  module TestHelper
    class RubyNode < BetterHtml::AST::Node
      BLOCK_EXPR = /\s*((\s+|\))do|\{)(\s*\|[^|]*\|)?\s*\Z/

      class ParseError < RuntimeError; end

      class Builder < ::Parser::Builders::Default
        def n(type, children, source_map)
          BetterHtml::TestHelper::RubyNode.new(type, children, loc: source_map)
        end
      end

      class << self
        def parse(code)
          parser = ::Parser::CurrentRuby.new(Builder.new)
          parser.diagnostics.ignore_warnings = true
          parser.diagnostics.all_errors_are_fatal = false
          parser.diagnostics.consumer = nil

          buf = ::Parser::Source::Buffer.new("(string)")
          buf.source = code.sub(BLOCK_EXPR, "")
          parser.parse(buf)
        end
      end

      def child_nodes
        children.select { |child| node?(child) }
      end

      def node?(current)
        current.is_a?(self.class)
      end

      def type?(wanted_type)
        Array.wrap(wanted_type).include?(type)
      end

      STATIC_TYPES = [:str, :int, :true, :false, :nil]

      def static_value?
        type?(STATIC_TYPES) ||
          (type?(:dstr) && !children.any? { |child| !child.type?(:str) })
      end

      def return_values
        Enumerator.new do |yielder|
          case type
          when :send, :csend, :ivar, *STATIC_TYPES
            yielder.yield(self)
          when :if, :masgn, :lvasgn
            # first child is ignored as it does not contain return values
            # for example, in `foo ? x : y` we only care about x and y, not foo
            children[1..-1].each do |child|
              child.return_values.each { |v| yielder.yield(v) } if node?(child)
            end
          else
            child_nodes.each do |child|
              child.return_values.each { |v| yielder.yield(v) }
            end
          end
        end
      end

      def static_return_value?
        return false if (possible_values = return_values.to_a).empty?

        possible_values.all?(&:static_value?)
      end

      def method_call?
        [:send, :csend].include?(type)
      end

      def hash?
        type?(:hash)
      end

      def pair?
        type?(:pair)
      end

      def begin?
        type?(:begin)
      end

      def method_name
        children[1] if method_call?
      end

      def arguments
        children[2..-1] if method_call?
      end

      def receiver
        children[0] if method_call?
      end

      def method_name?(name)
        method_call? && method_name == name
      end
    end
  end
end
