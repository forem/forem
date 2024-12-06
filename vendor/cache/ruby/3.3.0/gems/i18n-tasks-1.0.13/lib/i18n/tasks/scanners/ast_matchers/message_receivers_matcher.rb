# frozen_string_literal: true

require 'i18n/tasks/scanners/ast_matchers/base_matcher'
require 'i18n/tasks/scanners/results/occurrence'

module I18n::Tasks::Scanners::AstMatchers
  class MessageReceiversMatcher < BaseMatcher
    def initialize(scanner:, receivers:, message:)
      super(scanner: scanner)
      @receivers = Array(receivers)
      @message = message
    end

    # @param send_node [Parser::AST::Node]
    # @param method_name [Symbol, nil]
    # @param location [Parser::Source::Map]
    # @return [nil, [key, Occurrence]] full absolute key name and the occurrence.
    def convert_to_key_occurrences(send_node, method_name, location: send_node.loc)
      return unless node_match?(send_node)

      receiver = send_node.children[0]
      first_arg_node = send_node.children[2]
      second_arg_node = send_node.children[3]

      key = extract_string(first_arg_node)
      return if key.nil?

      key, default_arg = process_options(node: second_arg_node, key: key)

      return if key.nil?

      [
        full_key(receiver: receiver, key: key, location: location, calling_method: method_name),
        I18n::Tasks::Scanners::Results::Occurrence.from_range(
          raw_key: key,
          range: location.expression,
          default_arg: default_arg
        )
      ]
    end

    private

    def node_match?(node)
      receiver = node.children[0]
      message = node.children[1]

      @message == message && @receivers.any? { |r| r == receiver }
    end

    def full_key(receiver:, key:, location:, calling_method:)
      if receiver.nil?
        # Relative keys only work if called via `t()` but not `I18n.t()`:
        @scanner.absolute_key(
          key,
          location.expression.source_buffer.name,
          calling_method: calling_method
        )
      else
        key
      end
    end

    def process_options(node:, key:)
      return [key, nil] if node&.type != :hash

      scope_node = extract_hash_pair(node, 'scope')

      if scope_node
        scope = extract_string(
          scope_node.children[1],
          array_join_with: '.',
          array_flatten: true,
          array_reject_blank: true
        )
        return nil if scope.nil? && scope_node.type != :nil

        key = [scope, key].join('.') unless scope == ''
      end
      if default_arg_node = extract_hash_pair(node, 'default')
        default_arg = if default_arg_node.children[1]&.type == :hash
                        extract_hash(default_arg_node.children[1])
                      else
                        extract_string(default_arg_node.children[1])
                      end
      end

      [key, default_arg]
    end
  end
end
