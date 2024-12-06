# frozen_string_literal: true

# This file contains patches to RuboCop to support
# edge features and fix some bugs with 2.7+ syntax

require "parser/ruby-next/version"
require "ruby-next/language/parser"

module RuboCop
  # Transform Ruby Next parser version to a float, e.g.: "2.8.0.1" => 2.801
  RUBY_NEXT_VERSION = Parser::NEXT_VERSION.match(/(^\d+)\.(.+)$/)[1..-1].map { |part| part.delete(".") }.join(".").to_f

  class TargetRuby
    class RuboCopNextConfig < RuboCopConfig
      private

      def find_version
        version = @config.for_all_cops["TargetRubyVersion"]
        return unless version == "next"

        RUBY_NEXT_VERSION
      end
    end

    new_rubies = KNOWN_RUBIES + [RUBY_NEXT_VERSION]
    remove_const :KNOWN_RUBIES
    const_set :KNOWN_RUBIES, new_rubies

    new_sources = [RuboCopNextConfig] + SOURCES
    remove_const :SOURCES
    const_set :SOURCES, new_sources
  end
end

module RuboCop
  class ProcessedSource
    module ParserClassExt
      def parser_class(version)
        return super unless version == RUBY_NEXT_VERSION

        Parser::RubyNext
      end
    end

    prepend ParserClassExt
  end
end

# Let's make this file Ruby 2.2 compatible to avoid transpiling
# rubocop:disable Layout/HeredocIndentation
module RuboCop
  module AST
    module Traversal
      # Fixed in https://github.com/rubocop-hq/rubocop/pull/7786
      %i[case_match in_pattern find_pattern match_pattern match_pattern_p].each do |type|
        next if method_defined?(:"on_#{type}")
        module_eval(<<-RUBY, __FILE__, __LINE__ + 1)
def on_#{type}(node)
node.children.each { |child| send(:"on_\#{child.type}", child) if child }
nil
end
        RUBY
      end
    end

    unless Builder.method_defined?(:match_pattern_p)
      Builder.include RubyNext::Language::BuilderExt
    end
  end
end
# rubocop:enable Layout/HeredocIndentation

module RuboCop
  module Cop
    # Commissioner class is responsible for processing the AST and delegating
    # work to the specified cops.
    class Commissioner
      def on_meth_ref(node)
        trigger_responding_cops(:on_meth_ref, node)
      end

      unless method_defined?(:on_numblock)
        def on_numblock(node)
          children = node.children
          child = children[0]
          send(:"on_#{child.type}", child)
          # children[1] is the number of parameters
          return unless (child = children[2])

          send(:"on_#{child.type}", child)
        end
      end

      unless method_defined?(:on_def_e)
        def on_def_e(node)
          _name, _args_node, body_node = *node
          send(:"on_#{body_node.type}", body_node)
        end

        def on_defs_e(node)
          _definee_node, _name, _args_node, body_node = *node
          send(:"on_#{body_node.type}", body_node)
        end
      end
    end

    Commissioner.prepend(Module.new do
      # Ignore anonymous blocks
      def on_block_pass(node)
        return if node.children == [nil]

        super
      end

      def on_blockarg(node)
        return if node.children == [nil]

        super
      end
    end)

    module Layout
      require "rubocop/cop/layout/assignment_indentation"

      POTENTIAL_RIGHT_TYPES = %i[ivasgn lvasgn cvasgn gvasgn casgn masgn].freeze

      AssignmentIndentation.prepend(Module.new do
        def check_assignment(node, *)
          return if rightward?(node)
          super
        end

        private

        def rightward?(node)
          return unless POTENTIAL_RIGHT_TYPES.include?(node.type)

          return unless node.loc.operator

          assignee_loc =
            if node.type == :masgn
              node.children[0].loc.expression
            else
              node.loc.name
            end

          return false unless assignee_loc

          assignee_loc.begin_pos > node.loc.operator.end_pos
        end
      end)

      require "rubocop/cop/layout/empty_line_between_defs"
      EmptyLineBetweenDefs.prepend(Module.new do
        def def_end(node)
          return super unless node.loc.end.nil?

          node.loc.expression.line
        end
      end)

      require "rubocop/cop/layout/space_after_colon"
      SpaceAfterColon.prepend(Module.new do
        def on_pair(node)
          return if node.children[0].loc.last_column == node.children[1].loc.last_column

          super(node)
        end
      end)
    end

    module Style
      require "rubocop/cop/style/single_line_methods"
      SingleLineMethods.prepend(Module.new do
        def on_def(node)
          return if node.loc.end.nil?
          super
        end

        def on_defs(node)
          return if node.loc.end.nil?
          super
        end
      end)

      require "rubocop/cop/style/def_with_parentheses"
      DefWithParentheses.prepend(Module.new do
        def on_def(node)
          return if node.loc.end.nil?
          super
        end

        def on_defs(node)
          return if node.loc.end.nil?
          super
        end
      end)

      require "rubocop/cop/style/trailing_method_end_statement"
      TrailingMethodEndStatement.prepend(Module.new do
        def on_def(node)
          return if node.loc.end.nil?
          super
        end
      end)
    end
  end
end
