# frozen_string_literal: true

module ERBLint
  module Utils
    class RubyToERB
      class Error < StandardError; end

      class << self
        def html_options_to_tag_attributes(hash_node)
          hash_node.children.map do |pair_node|
            key_node, value_node = *pair_node
            key = ruby_to_erb(key_node, '=') { |s| s.tr('_', '-') }
            value = ruby_to_erb(value_node, '=') { |s| escape_quote(s) }
            [key, "\"#{value}\""].join('=')
          end.join(' ')
        end

        def ruby_to_erb(node, indicator = nil, &block)
          return node if node.nil? || node.is_a?(String)
          case node.type
          when :str, :sym
            s = node.children.first.to_s
            s = yield s if block_given?
            s
          when :true, :false
            node.type.to_s
          when :nil
            ""
          when :dstr
            node.children.map do |child|
              case child.type
              when :str
                ruby_to_erb(child, indicator, &block)
              when :begin
                ruby_to_erb(child.children.first, indicator, &block)
              else
                raise Error, "unexpected #{child.type} in :dstr node"
              end
            end.join
          else
            "<%#{indicator} #{node.loc.expression.source} %>"
          end
        end

        def escape_quote(str)
          str.gsub('"', '&quot;')
        end
      end
    end
  end
end
