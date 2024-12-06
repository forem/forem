# frozen_string_literal: true

module Solargraph
  module Parser
    module Legacy
      module NodeProcessors
        class SendNode < Parser::NodeProcessor::Base
          include Legacy::NodeMethods

          def process
            if node.children[0].nil?
              if [:private, :public, :protected].include?(node.children[1])
                process_visibility
              elsif node.children[1] == :module_function
                process_module_function
              elsif [:attr_reader, :attr_writer, :attr_accessor].include?(node.children[1])
                process_attribute
              elsif node.children[1] == :include
                process_include
              elsif node.children[1] == :extend
                process_extend
              elsif node.children[1] == :prepend
                process_prepend
              elsif node.children[1] == :require
                process_require
              elsif node.children[1] == :autoload
                process_autoload
              elsif node.children[1] == :private_constant
                process_private_constant
              elsif node.children[1] == :alias_method && node.children[2] && node.children[2] && node.children[2].type == :sym && node.children[3] && node.children[3].type == :sym
                process_alias_method
              elsif node.children[1] == :private_class_method && node.children[2].is_a?(AST::Node)
                # Processing a private class can potentially handle children on its own
                return if process_private_class_method
              end
            elsif node.children[1] == :require && node.children[0].to_s == '(const nil :Bundler)'
              pins.push Pin::Reference::Require.new(Solargraph::Location.new(region.filename, Solargraph::Range.from_to(0, 0, 0, 0)), 'bundler/require')
            end
            process_children
          end

          private

          # @return [void]
          def process_visibility
            if (node.children.length > 2)
              node.children[2..-1].each do |child|
                if child.is_a?(AST::Node) && (child.type == :sym || child.type == :str)
                  name = child.children[0].to_s
                  matches = pins.select{ |pin| pin.is_a?(Pin::Method) && pin.name == name && pin.namespace == region.closure.full_context.namespace && pin.context.scope == (region.scope || :instance)}
                  matches.each do |pin|
                    # @todo Smelly instance variable access
                    pin.instance_variable_set(:@visibility, node.children[1])
                  end
                else
                  process_children region.update(visibility: node.children[1])
                end
              end
            else
              # @todo Smelly instance variable access
              region.instance_variable_set(:@visibility, node.children[1])
            end
          end

          # @return [void]
          def process_attribute
            node.children[2..-1].each do |a|
              loc = get_node_location(node)
              clos = region.closure
              cmnt = comments_for(node)
              if node.children[1] == :attr_reader || node.children[1] == :attr_accessor
                pins.push Solargraph::Pin::Method.new(
                  location: loc,
                  closure: clos,
                  name: a.children[0].to_s,
                  comments: cmnt,
                  scope: region.scope || :instance,
                  visibility: region.visibility,
                  attribute: true
                )
              end
              if node.children[1] == :attr_writer || node.children[1] == :attr_accessor
                pins.push Solargraph::Pin::Method.new(
                  location: loc,
                  closure: clos,
                  name: "#{a.children[0]}=",
                  comments: cmnt,
                  scope: region.scope || :instance,
                  visibility: region.visibility,
                  attribute: true
                )
                pins.last.parameters.push Pin::Parameter.new(name: 'value', decl: :arg, closure: pins.last)
                if pins.last.return_type.defined?
                  pins.last.docstring.add_tag YARD::Tags::Tag.new(:param, '', pins.last.return_type.to_s.split(', '), 'value')
                end
              end
            end
          end

          # @return [void]
          def process_include
            if node.children[2].is_a?(AST::Node) && node.children[2].type == :const
              cp = region.closure
              node.children[2..-1].each do |i|
                type = region.scope == :class ? Pin::Reference::Extend : Pin::Reference::Include
                pins.push type.new(
                  location: get_node_location(i),
                  closure: cp,
                  name: unpack_name(i)
                )
              end
            end
          end

          def process_prepend
            if node.children[2].is_a?(AST::Node) && node.children[2].type == :const
              cp = region.closure
              node.children[2..-1].each do |i|
                pins.push Pin::Reference::Prepend.new(
                  location: get_node_location(i),
                  closure: cp,
                  name: unpack_name(i)
                )
              end
            end
          end

          # @return [void]
          def process_extend
            node.children[2..-1].each do |i|
              loc = get_node_location(node)
              if i.type == :self
                pins.push Pin::Reference::Extend.new(
                  location: loc,
                  closure: region.closure,
                  name: region.closure.full_context.namespace
                )
              else
                pins.push Pin::Reference::Extend.new(
                  location: loc,
                  closure: region.closure,
                  name: unpack_name(i)
                )
              end
            end
          end

          # @return [void]
          def process_require
            if node.children[2].is_a?(AST::Node) && node.children[2].type == :str
              path = node.children[2].children[0].to_s
              pins.push Pin::Reference::Require.new(get_node_location(node), path)
            end
          end

          # @return [void]
          def process_autoload
            if node.children[3].is_a?(AST::Node) && node.children[3].type == :str
              path = node.children[3].children[0].to_s
              pins.push Pin::Reference::Require.new(get_node_location(node), path)
            end
          end

          # @return [void]
          def process_module_function
            if node.children[2].nil?
              # @todo Smelly instance variable access
              region.instance_variable_set(:@visibility, :module_function)
            elsif node.children[2].type == :sym || node.children[2].type == :str
              node.children[2..-1].each do |x|
                cn = x.children[0].to_s
                ref = pins.select{ |p| p.is_a?(Pin::Method) && p.namespace == region.closure.full_context.namespace && p.name == cn }.first
                unless ref.nil?
                  pins.delete ref
                  mm = Solargraph::Pin::Method.new(
                    location: ref.location,
                    closure: ref.closure,
                    name: ref.name,
                    parameters: ref.parameters,
                    comments: ref.comments,
                    scope: :class,
                    visibility: :public,
                    node: ref.node
                  )
                  cm = Solargraph::Pin::Method.new(
                    location: ref.location,
                    closure: ref.closure,
                    name: ref.name,
                    parameters: ref.parameters,
                    comments: ref.comments,
                    scope: :instance,
                    visibility: :private,
                    node: ref.node)
                  pins.push mm, cm
                  pins.select{|pin| pin.is_a?(Pin::InstanceVariable) && pin.closure.path == ref.path}.each do |ivar|
                    pins.delete ivar
                    pins.push Solargraph::Pin::InstanceVariable.new(
                      location: ivar.location,
                      closure: cm,
                      name: ivar.name,
                      comments: ivar.comments,
                      assignment: ivar.assignment
                    )
                    pins.push Solargraph::Pin::InstanceVariable.new(
                      location: ivar.location,
                      closure: mm,
                      name: ivar.name,
                      comments: ivar.comments,
                      assignment: ivar.assignment
                    )
                  end
                end
              end
            elsif node.children[2].type == :def
              NodeProcessor.process node.children[2], region.update(visibility: :module_function), pins, locals
            end
          end

          # @return [void]
          def process_private_constant
            if node.children[2] && (node.children[2].type == :sym || node.children[2].type == :str)
              cn = node.children[2].children[0].to_s
              ref = pins.select{|p| [Solargraph::Pin::Namespace, Solargraph::Pin::Constant].include?(p.class) && p.namespace == region.closure.full_context.namespace && p.name == cn}.first
              # HACK: Smelly instance variable access
              ref.instance_variable_set(:@visibility, :private) unless ref.nil?
            end
          end

          # @return [void]
          def process_alias_method
            loc = get_node_location(node)
            pins.push Solargraph::Pin::MethodAlias.new(
              location: get_node_location(node),
              closure: region.closure,
              name: node.children[2].children[0].to_s,
              original: node.children[3].children[0].to_s,
              scope: region.scope || :instance
            )
          end

          # @return [Boolean]
          def process_private_class_method
            if node.children[2].type == :sym || node.children[2].type == :str
              ref = pins.select { |p| p.is_a?(Pin::Method) && p.namespace == region.closure.full_context.namespace && p.name == node.children[2].children[0].to_s }.first
              # HACK: Smelly instance variable access
              ref.instance_variable_set(:@visibility, :private) unless ref.nil?
              false
            else
              process_children region.update(scope: :class, visibility: :private)
              true
            end
          end
        end
      end
    end
  end
end
