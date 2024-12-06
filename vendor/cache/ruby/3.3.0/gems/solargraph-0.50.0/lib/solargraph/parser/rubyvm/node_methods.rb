module Solargraph
  module Parser
    module Rubyvm
      module NodeMethods
        module_function

        # @param node [RubyVM::AbstractSyntaxTree::Node]
        # @return [String]
        def unpack_name node
          pack_name(node).join('::')
        end

        # @param node [RubyVM::AbstractSyntaxTree::Node]
        # @return [Array<String>]
        def pack_name(node)
          parts = []
          if node.is_a?(RubyVM::AbstractSyntaxTree::Node)
            parts.push '' if node.type == :COLON3
            node.children.each { |n|
              if n.is_a?(RubyVM::AbstractSyntaxTree::Node)
                parts += pack_name(n)
              else
                parts.push n unless n.nil?
              end
            }
          end
          parts
        end

        # @param node [RubyVM::AbstractSyntaxTree::Node]
        # @return [String, nil]
        def infer_literal_node_type node
          return nil unless Parser.is_ast_node?(node)
          case node.type
          when :LIT, :STR
            "::#{node.children.first.class.to_s}"
          when :DSTR
            "::String"
          when :ARRAY, :ZARRAY, :LIST, :ZLIST
            '::Array'
          when :HASH
            '::Hash'
          when :DOT2, :DOT3
            '::Range'
          when :TRUE, :FALSE
            '::Boolean'
          when :SCOPE
            infer_literal_node_type(node.children[2])
          end
        end

        def returns_from node
          return [] unless Parser.is_ast_node?(node)
          if node.type == :SCOPE
            # node.children.select { |n| n.is_a?(RubyVM::AbstractSyntaxTree::Node) }.map { |n| DeepInference.get_return_nodes(n) }.flatten
            DeepInference.get_return_nodes(node.children[2])
          else
            DeepInference.get_return_nodes(node)
          end
        end

        def const_nodes_from node
          return [] unless Parser.is_ast_node?(node)
          result = []
          if [:CONST, :COLON2, :COLON3].include?(node.type)
            result.push node
          else
            node.children.each { |child| result.concat const_nodes_from(child) }
          end
          result
        end

        def call_nodes_from node
          return [] unless Parser.is_ast_node?(node)
          result = []
          if node.type == :ITER
            result.push node.children[0]
            node.children[1..-1].each { |child| result.concat call_nodes_from(child) }
          elsif node.type == :MASGN
            # @todo We're treating a mass assignment as a call node, but the
            #   type checker still needs the logic to handle it.
            result.push node
          elsif [:CALL, :VCALL, :FCALL, :ATTRASGN, :OPCALL].include?(node.type)
            result.push node
            node.children.each { |child| result.concat call_nodes_from(child) }
          else
            node.children.each { |child| result.concat call_nodes_from(child) }
          end
          result
        end

        def convert_hash node
          return {} unless node?(node) && node.type == :HASH
          return convert_hash(node.children[0].children[1]) if splatted_hash?(node)
          return {} unless node?(node.children[0])
          result = {}
          index = 0
          until index > node.children[0].children.length - 2
            k = node.children[0].children[index]
            return {} unless node?(k)
            v = node.children[0].children[index + 1]
            result[k.children[0]] = Solargraph::Parser.chain(v)
            index += 2
          end
          result
        end

        def splatted_hash? node
          splatted_node?(node) && node.children[0].children[1].type == :HASH
        end

        def splatted_node? node
          node?(node.children[0]) &&
            [:ARRAY, :LIST].include?(node.children[0].type) &&
            node.children[0].children[0].nil? &&
            node?(node.children[0].children[1])
        end

        def splatted_call? node
          return false unless Parser.is_ast_node?(node)
          splatted_node?(node) && node.children[0].children[1].type != :HASH
        end

        def any_splatted_call?(nodes)
          nodes.any? { |n| splatted_call?(n) }
        end

        def node? node
          node.is_a?(RubyVM::AbstractSyntaxTree::Node)
        end

        # @param cursor [Solargraph::Source::Cursor]
        def find_recipient_node cursor
          if cursor.source.synchronized?
            NodeMethods.synchronized_find_recipient_node cursor
          else
            NodeMethods.unsynchronized_find_recipient_node cursor
          end
        end

        class << self
          protected

          # @param cursor [Source::Cursor]
          # @return [RubyVM::AbstractSyntaxTree::Node, nil]
          def synchronized_find_recipient_node cursor
            cursor = maybe_adjust_cursor(cursor)
            source = cursor.source
            position = cursor.position
            offset = cursor.offset
            tree = source.tree_at(position.line, position.column)
              .select { |n| [:FCALL, :VCALL, :CALL].include?(n.type) }
            unless source.repaired?
              tree.shift while tree.first && !source.code_for(tree.first).strip.end_with?(')')
            end
            return tree.first if source.repaired? || source.code[0..offset-1] =~ /\(\s*$/
            tree.each do |node|
              args = node.children.find { |c| Parser.is_ast_node?(c) && [:ARRAY, :ZARRAY, :LIST].include?(c.type) }
              if args
                match = source.code[0..offset-1].match(/,[^\)]*\z/)
                rng = Solargraph::Range.from_node(args)
                if match
                  rng = Solargraph::Range.new(rng.start, position)
                end
                return node if rng.contain?(position)
              end
            end
            nil
          end

          # @param cursor [Source::Cursor]
          # @return [Source::Cursor]
          def maybe_adjust_cursor cursor
            return cursor unless (cursor.source.repaired? && cursor.source.code[cursor.offset - 1] == '(') || [',', ' '].include?(cursor.source.code[cursor.offset - 1])
            cursor.source.cursor_at([cursor.position.line, cursor.position.column - 1])
          end

          def unsynchronized_find_recipient_node cursor
            source = cursor.source
            position = cursor.position
            offset = cursor.offset
            if source.code[0..offset-1] =~ /\([A-Zaz0-9_\s]*\z$/
              tree = source.tree_at(position.line, position.column - 1)
              if tree.first && [:FCALL, :VCALL, :CALL].include?(tree.first.type)
                return tree.first
              else
                return nil
              end
            else
              match = source.code[0..offset-1].match(/[\(,][A-Zaz0-9_\s]*\z/)
              if match
                moved = Position.from_offset(source.code, offset - match[0].length)
                tree = source.tree_at(moved.line, moved.column)
                tree.shift if match[0].start_with?(',')
                tree.shift while tree.first && ![:FCALL, :VCALL, :CALL].include?(tree.first.type)
                if tree.first && [:FCALL, :VCALL, :CALL].include?(tree.first.type)
                  return tree.first
                end
              end
              return nil
            end
          end
        end

        module DeepInference
          class << self
            CONDITIONAL = [:IF, :UNLESS]
            REDUCEABLE = [:BLOCK]
            SKIPPABLE = [:DEFN, :DEFS, :CLASS, :SCLASS, :MODULE]

            # @param node [Parser::AST::Node]
            # @return [Array<Parser::AST::Node>]
            def get_return_nodes node
              return [] unless node.is_a?(RubyVM::AbstractSyntaxTree::Node)
              result = []
              if REDUCEABLE.include?(node.type)
                result.concat get_return_nodes_from_children(node)
              elsif CONDITIONAL.include?(node.type)
                result.concat reduce_to_value_nodes(node.children[1..-1])
              elsif node.type == :RESCUE
                result.concat reduce_to_value_nodes([node.children[0]])
                result.concat reduce_to_value_nodes(node.children[1..-2])
              elsif node.type == :OR
                result.concat reduce_to_value_nodes(node.children)
              elsif node.type == :RETURN
                result.concat reduce_to_value_nodes([node.children[0]])
              elsif node.type == :ITER
                result.push node
                result.concat get_return_nodes_only(node.children[1])
              elsif node.type == :CASE
                node.children[1..-1].each do |cc|
                  result.concat reduce_to_value_nodes(cc.children[1..-1])
                end
              else
                result.push node
              end
              result
            end

            private

            def get_return_nodes_from_children parent
              result = []
              nodes = parent.children.select{|n| n.is_a?(RubyVM::AbstractSyntaxTree::Node)}
              nodes.each_with_index do |node, idx|
                if node.type == :BLOCK
                  result.concat get_return_nodes_only(node.children[2])
                elsif SKIPPABLE.include?(node.type)
                  next
                elsif CONDITIONAL.include?(node.type)
                  result.concat get_return_nodes_only(node)
                elsif node.type == :RETURN
                  result.concat reduce_to_value_nodes([node.children[0]])
                  # Return the result here because the rest of the code is
                  # unreachable
                  return result
                else
                  result.concat get_return_nodes_only(node)
                end
                result.concat reduce_to_value_nodes([nodes.last]) if idx == nodes.length - 1
              end
              result
            end

            def get_return_nodes_only parent
              return [] unless parent.is_a?(RubyVM::AbstractSyntaxTree::Node)
              result = []
              nodes = parent.children.select{|n| n.is_a?(RubyVM::AbstractSyntaxTree::Node)}
              nodes.each do |node|
                next if SKIPPABLE.include?(node.type)
                if node.type == :RETURN
                  result.concat reduce_to_value_nodes([node.children[0]])
                  # Return the result here because the rest of the code is
                  # unreachable
                  return result
                else
                  result.concat get_return_nodes_only(node)
                end
              end
              result
            end

            def reduce_to_value_nodes nodes
              result = []
              nodes.each do |node|
                if !node.is_a?(RubyVM::AbstractSyntaxTree::Node)
                  result.push nil
                elsif REDUCEABLE.include?(node.type)
                  result.concat get_return_nodes_from_children(node)
                elsif CONDITIONAL.include?(node.type)
                  result.concat reduce_to_value_nodes(node.children[1..-1])
                elsif node.type == :RETURN
                  if node.children[0].nil?
                    result.push nil
                  else
                    result.concat get_return_nodes(node.children[0])
                  end
                elsif node.type == :OR
                  result.concat reduce_to_value_nodes(node.children)
                elsif node.type == :BLOCK
                  result.concat get_return_nodes_only(node.children[2])
                elsif node.type == :RESBODY
                  result.concat reduce_to_value_nodes([node.children[1]])
                else
                  result.push node
                end
              end
              result
            end
          end
        end
      end
    end
  end
end
