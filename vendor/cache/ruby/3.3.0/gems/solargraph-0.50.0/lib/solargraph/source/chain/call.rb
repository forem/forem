# frozen_string_literal: true

module Solargraph
  class Source
    class Chain
      class Call < Link
        # @return [String]
        attr_reader :word

        # @return [Array<Chain>]
        attr_reader :arguments

        # @param word [String]
        # @param arguments [Array<Chain>]
        # @param with_block [Boolean] True if the chain is inside a block
        # @param head [Boolean] True if the call is the start of its chain
        def initialize word, arguments = [], with_block = false
          @word = word
          @arguments = arguments
          @with_block = with_block
        end

        def with_block?
          @with_block
        end

        # @param api_map [ApiMap]
        # @param name_pin [Pin::Base]
        # @param locals [Array<Pin::Base>]
        def resolve api_map, name_pin, locals
          return super_pins(api_map, name_pin) if word == 'super'
          found = if head?
            locals.select { |p| p.name == word }
          else
            []
          end
          return inferred_pins(found, api_map, name_pin.context, locals) unless found.empty?
          # @param [ComplexType::UniqueType]
          pins = name_pin.binder.each_unique_type.flat_map do |context|
            api_map.get_method_stack(context.namespace, word, scope: context.scope)
          end
          return [] if pins.empty?
          inferred_pins(pins, api_map, name_pin.context, locals)
        end

        private

        # @param pins [Array<Pin::Base>]
        # @param api_map [ApiMap]
        # @param context [ComplexType]
        # @param locals [Pin::LocalVariable]
        # @return [Array<Pin::Base>]
        def inferred_pins pins, api_map, context, locals
          result = pins.map do |p|
            next p unless p.is_a?(Pin::Method)
            overloads = p.signatures
            # next p if overloads.empty?
            type = ComplexType::UNDEFINED
            overloads.each do |ol|
              next unless arguments_match(arguments, ol)
              # next if ol.parameters.last && ol.parameters.last.first.start_with?('&') && ol.parameters.last.last.nil? && !with_block?
              match = true
              arguments.each_with_index do |arg, idx|
                param = ol.parameters[idx]
                if param.nil?
                  match = false unless ol.parameters.any?(&:restarg?)
                  break
                end
                atype = arg.infer(api_map, Pin::ProxyType.anonymous(context), locals)
                # @todo Weak type comparison
                # unless atype.tag == param.return_type.tag || api_map.super_and_sub?(param.return_type.tag, atype.tag)
                unless param.return_type.undefined? || atype.name == param.return_type.name || api_map.super_and_sub?(param.return_type.name, atype.name)
                  match = false
                  break
                end
              end
              if match
                type = extra_return_type(p.docstring, context)
                break if type
                type = with_params(ol.return_type.self_to(context.to_s), context).qualify(api_map, context.namespace) if ol.return_type.defined?
                type ||= ComplexType::UNDEFINED
              end
              break if type.defined?
            end
            next p.proxy(type) if type.defined?
            type = extra_return_type(p.docstring, context)
            if type
              next Solargraph::Pin::Method.new(
                location: p.location,
                closure: p.closure,
                name: p.name,
                comments: "@return [#{context.subtypes.first.to_s}]",
                scope: p.scope,
                visibility: p.visibility,
                parameters: p.parameters,
                node: p.node
              )
            end
            if p.is_a?(Pin::Method) && !p.macros.empty?
              result = process_macro(p, api_map, context, locals)
              next result unless result.return_type.undefined?
            elsif !p.directives.empty?
              result = process_directive(p, api_map, context, locals)
              next result unless result.return_type.undefined?
            end
            p
          end
          result.map do |pin|
            if pin.path == 'Class#new' && context.tag != 'Class'
              pin.proxy(ComplexType.try_parse(context.namespace))
            else
              next pin if pin.return_type.undefined?
              selfy = pin.return_type.self_to(context.tag)
              selfy == pin.return_type ? pin : pin.proxy(selfy)
            end
          end
        end

        # @param pin [Pin::Method]
        # @param api_map [ApiMap]
        # @param context [ComplexType]
        # @param locals [Pin::Base]
        # @return [Pin::Base]
        def process_macro pin, api_map, context, locals
          pin.macros.each do |macro|
            result = inner_process_macro(pin, macro, api_map, context, locals)
            return result unless result.return_type.undefined?
          end
          Pin::ProxyType.anonymous(ComplexType::UNDEFINED)
        end

        # @param pin [Pin::Method]
        # @param api_map [ApiMap]
        # @param context [ComplexType]
        # @param locals [Pin::Base]
        # @return [Pin::ProxyType]
        def process_directive pin, api_map, context, locals
          pin.directives.each do |dir|
            macro = api_map.named_macro(dir.tag.name)
            next if macro.nil?
            result = inner_process_macro(pin, macro, api_map, context, locals)
            return result unless result.return_type.undefined?
          end
          Pin::ProxyType.anonymous ComplexType::UNDEFINED
        end

        # @param pin [Pin]
        # @param macro [YARD::Tags::MacroDirective]
        # @param api_map [ApiMap]
        # @param context [ComplexType]
        # @param locals [Array<Pin::Base>]
        # @return [Pin::ProxyType]
        def inner_process_macro pin, macro, api_map, context, locals
          vals = arguments.map{ |c| Pin::ProxyType.anonymous(c.infer(api_map, pin, locals)) }
          txt = macro.tag.text.clone
          if txt.empty? && macro.tag.name
            named = api_map.named_macro(macro.tag.name)
            txt = named.tag.text.clone if named
          end
          i = 1
          vals.each do |v|
            txt.gsub!(/\$#{i}/, v.context.namespace)
            i += 1
          end
          docstring = Solargraph::Source.parse_docstring(txt).to_docstring
          tag = docstring.tag(:return)
          unless tag.nil? || tag.types.nil?
            return Pin::ProxyType.anonymous(ComplexType.try_parse(*tag.types))
          end
          Pin::ProxyType.anonymous(ComplexType::UNDEFINED)
        end

        # @param docstring [YARD::Docstring]
        # @param context [ComplexType]
        # @return [ComplexType]
        def extra_return_type docstring, context
          if docstring.has_tag?(:return_single_parameter) #&& context.subtypes.one?
            return context.subtypes.first || ComplexType::UNDEFINED
          elsif docstring.has_tag?(:return_value_parameter) && context.value_types.one?
            return context.value_types.first
          end
          nil
        end

        # @param arguments [Array<Chain>]
        # @param signature [Pin::Signature]
        # @return [Boolean]
        def arguments_match arguments, signature
          parameters = signature.parameters
          argcount = arguments.length
          parcount = parameters.length
          parcount -= 1 if !parameters.empty? && parameters.last.block?
          return false if signature.block? && !with_block?
          return false if argcount < parcount && !(argcount == parcount - 1 && parameters.last.restarg?)
          true
        end

        # @param api_map [ApiMap]
        # @param name_pin [Pin::Base]
        # @return [Array<Pin::Base>]
        def super_pins api_map, name_pin
          pins = api_map.get_method_stack(name_pin.namespace, name_pin.name, scope: name_pin.context.scope)
          pins.reject{|p| p.path == name_pin.path}
        end

        # @param type [ComplexType]
        # @param context [ComplexType]
        def with_params type, context
          return type unless type.to_s.include?('$')
          ComplexType.try_parse(type.to_s.gsub('$', context.value_types.map(&:tag).join(', ')).gsub('<>', ''))
        end
      end
    end
  end
end
