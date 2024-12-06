# frozen_string_literal: true

module I18n::Tasks::Scanners::AstMatchers
  class BaseMatcher
    def initialize(scanner:)
      @scanner = scanner
    end

    def convert_to_key_occurrences(send_node, _method_name, location: send_node.loc)
      fail('Not implemented')
    end

    protected

    # If the node type is of `%i(sym str int false true)`, return the value as a string.
    # Otherwise, if `config[:strict]` is `false` and the type is of `%i(dstr dsym)`,
    # return the source as if it were a string.
    #
    # @param node [Parser::AST::Node]
    # @param array_join_with [String, nil] if set to a string, arrays will be processed and their elements joined.
    # @param array_flatten [Boolean] if true, nested arrays are flattened,
    #     otherwise their source is copied and surrounded by #{}. No effect unless `array_join_with` is set.
    # @param array_reject_blank [Boolean] if true, empty strings and `nil`s are skipped.
    #      No effect unless `array_join_with` is set.
    # @return [String, nil] `nil` is returned only when a dynamic value is encountered in strict mode
    #     or the node type is not supported.
    def extract_string(node, array_join_with: nil, array_flatten: false, array_reject_blank: false) # rubocop:disable Metrics/AbcSize, Metrics/PerceivedComplexity
      return if node.nil?

      if %i[sym str int].include?(node.type)
        node.children[0].to_s
      elsif %i[true false].include?(node.type)
        node.type.to_s
      elsif node.type == :nil
        ''
      elsif node.type == :array && array_join_with
        extract_array_as_string(
          node,
          array_join_with: array_join_with,
          array_flatten: array_flatten,
          array_reject_blank: array_reject_blank
        ).tap do |str|
          # `nil` is returned when a dynamic value is encountered in strict mode. Propagate:
          return nil if str.nil?
        end
      elsif !@scanner.config[:strict] && %i[dsym dstr].include?(node.type)
        node.children.map do |child|
          if %i[sym str].include?(child.type)
            child.children[0].to_s
          else
            child.loc.expression.source
          end
        end.join
      end
    end

    # Extract the whole hash from a node of type `:hash`
    #
    # @param node [AST::Node] a node of type `:hash`.
    # @return [Hash] the whole hash from the node
    def extract_hash(node)
      return {} if node.nil?

      if node.type == :hash
        node.children.each_with_object({}) do |pair, h|
          key = pair.children[0].children[0].to_s
          value = pair.children[1].children[0]
          h[key] = value
        end
      end
    end

    # Extract a hash pair with a given literal key.
    #
    # @param node [AST::Node] a node of type `:hash`.
    # @param key [String] node key as a string (indifferent symbol-string matching).
    # @return [AST::Node, nil] a node of type `:pair` or nil.
    def extract_hash_pair(node, key)
      node.children.detect do |child|
        next unless child.type == :pair

        key_node = child.children[0]
        %i[sym str].include?(key_node.type) && key_node.children[0].to_s == key
      end
    end

    # Extract an array as a single string.
    #
    # @param array_join_with [String] joiner of the array elements.
    # @param array_flatten [Boolean] if true, nested arrays are flattened,
    #     otherwise their source is copied and surrounded by #{}.
    # @param array_reject_blank [Boolean] if true, empty strings and `nil`s are skipped.
    # @return [String, nil] `nil` is returned only when a dynamic value is encountered in strict mode.
    def extract_array_as_string(node, array_join_with:, array_flatten: false, array_reject_blank: false)
      children_strings = node.children.map do |child|
        if %i[sym str int true false].include?(child.type)
          extract_string child
        else
          # ignore dynamic argument in strict mode
          return nil if @scanner.config[:strict]

          if %i[dsym dstr].include?(child.type) || (child.type == :array && array_flatten)
            extract_string(child, array_join_with: array_join_with)
          else
            "\#{#{child.loc.expression.source}}"
          end
        end
      end
      if array_reject_blank
        children_strings.reject! do |x|
          # empty strings and nils in the scope argument are ignored by i18n
          x == ''
        end
      end
      children_strings.join(array_join_with)
    end
  end
end
