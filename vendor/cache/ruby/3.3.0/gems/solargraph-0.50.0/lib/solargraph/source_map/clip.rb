# frozen_string_literal: true

module Solargraph
  class SourceMap
    # A static analysis tool for obtaining definitions, completions,
    # signatures, and type inferences from a cursor.
    #
    class Clip
      # @param api_map [ApiMap]
      # @param cursor [Source::Cursor]
      def initialize api_map, cursor
        @api_map = api_map
        @cursor = cursor
      end

      # @return [Array<Pin::Base>]
      def define
        return [] if cursor.comment? || cursor.chain.literal?
        result = cursor.chain.define(api_map, block, locals)
        result.concat((source_map.pins + source_map.locals).select{ |p| p.name == cursor.word && p.location.range.contain?(cursor.position) }) if result.empty?
        result
      end

      # @return [Completion]
      def complete
        return package_completions([]) if !source_map.source.parsed? || cursor.string?
        return package_completions(api_map.get_symbols) if cursor.chain.literal? && cursor.chain.links.last.word == '<Symbol>'
        return Completion.new([], cursor.range) if cursor.chain.literal?
        if cursor.comment?
          tag_complete
        else
          code_complete
        end
      end

      # @return [Array<Pin::Base>]
      def signify
        return [] unless cursor.argument?
        chain = Parser.chain(cursor.recipient_node, cursor.filename)
        chain.define(api_map, context_pin, locals).select { |pin| pin.is_a?(Pin::Method) }
      end

      # @return [ComplexType]
      def infer
        result = cursor.chain.infer(api_map, block, locals)
        if result.tag == 'Class'
          # HACK: Exception to return Object from Class#new
          dfn = cursor.chain.define(api_map, block, locals).first
          return ComplexType.try_parse('Object') if dfn && dfn.path == 'Class#new'
        end
        return result unless result.tag == 'self'
        ComplexType.try_parse(cursor.chain.base.infer(api_map, block, locals).namespace)
      end

      # Get an array of all the locals that are visible from the cursors's
      # position. Locals can be local variables, method parameters, or block
      # parameters. The array starts with the nearest local pin.
      #
      # @return [Array<Solargraph::Pin::Base>]
      def locals
        @locals ||= source_map.locals_at(location)
      end

      def gates
        block.gates
      end

      def in_block?
        return @in_block unless @in_block.nil?
        @in_block = begin
          tree = cursor.source.tree_at(cursor.position.line, cursor.position.column)
          Parser.is_ast_node?(tree[1]) && [:block, :ITER].include?(tree[1].type)
        end
      end

      # @param phrase [String]
      # @return [Array<Solargraph::Pin::Base>]
      def translate phrase
        chain = Parser.chain(Parser.parse(phrase))
        chain.define(api_map, block, locals)
      end

      private

      # @return [ApiMap]
      attr_reader :api_map

      # @return [Source::Cursor]
      attr_reader :cursor

      # @return [SourceMap]
      def source_map
        @source_map ||= api_map.source_map(cursor.filename)
      end

      def location
        Location.new(source_map.filename, Solargraph::Range.new(cursor.position, cursor.position))
      end

      # @return [Solargraph::Pin::Base]
      def block
        @block ||= source_map.locate_block_pin(cursor.node_position.line, cursor.node_position.character)
      end

      # The context at the current position.
      #
      # @return [Pin::Base]
      def context_pin
        @context_pin ||= source_map.locate_named_path_pin(cursor.node_position.line, cursor.node_position.character)
      end

      # @return [Array<Pin::Base>]
      def yielded_self_pins
        return [] unless block.is_a?(Pin::Block) && block.receiver
        chain = Parser.chain(block.receiver, source_map.source.filename)
        receiver_pin = chain.define(api_map, context_pin, locals).first
        return [] if receiver_pin.nil?
        result = []
        ys = receiver_pin.docstring.tag(:yieldpublic)
        unless ys.nil? || ys.types.empty?
          ysct = ComplexType.try_parse(*ys.types).qualify(api_map, receiver_pin.context.namespace)
          result.concat api_map.get_complex_type_methods(ysct, '', false)
        end
        result
      end

      # @return [Array<Pin::KeywordParam]
      def complete_keyword_parameters
        return [] unless cursor.argument? && cursor.chain.links.one? && cursor.word =~ /^[a-z0-9_]*:?$/
        pins = signify
        result = []
        done = []
        pins.each do |pin|
          pin.parameters.each do |param|
            next if done.include?(param.name)
            done.push param.name
            next unless param.keyword?
            result.push Pin::KeywordParam.new(pin.location, "#{param.name}:")
          end
          if !pin.parameters.empty? && pin.parameters.last.kwrestarg?
            pin.docstring.tags(:param).each do |tag|
              next if done.include?(tag.name)
              done.push tag.name
              result.push Pin::KeywordParam.new(pin.location, "#{tag.name}:")
            end
          end
        end
        result
      end

      # @param result [Array<Pin::Base>]
      # @return [Completion]
      def package_completions result
        frag_start = cursor.start_of_word.to_s.downcase
        filtered = result.uniq(&:name).select { |s|
          s.name.downcase.start_with?(frag_start) &&
            (!s.is_a?(Pin::Method) || s.name.match(/^[a-z0-9_]+(\!|\?|=)?$/i))
        }
        Completion.new(filtered, cursor.range)
      end

      def tag_complete
        result = []
        match = source_map.code[0..cursor.offset-1].match(/[\[<, ]([a-z0-9_:]*)\z/i)
        if match
          full = match[1]
          if full.include?('::')
            if full.end_with?('::')
              result.concat api_map.get_constants(full[0..-3], *gates)
            else
              result.concat api_map.get_constants(full.split('::')[0..-2].join('::'), *gates)
            end
          else
            result.concat api_map.get_constants('', full.end_with?('::') ? '' : context_pin.full_context.namespace, *gates) #.select { |pin| pin.name.start_with?(full) }
          end
        end
        package_completions(result)
      end

      def code_complete
        result = []
        result.concat complete_keyword_parameters
        if cursor.chain.constant? || cursor.start_of_constant?
          full = cursor.chain.links.first.word
          type = if cursor.chain.undefined?
            cursor.chain.base.infer(api_map, context_pin, locals)
          else
            if full.include?('::') && cursor.chain.links.length == 1
              ComplexType.try_parse(full.split('::')[0..-2].join('::'))
            elsif cursor.chain.links.length > 1
              ComplexType.try_parse(full)
            else
              ComplexType::UNDEFINED
            end
          end
          if type.undefined?
            if full.include?('::')
              result.concat api_map.get_constants(full, *gates)
            else
              result.concat api_map.get_constants('', cursor.start_of_constant? ? '' : context_pin.full_context.namespace, *gates) #.select { |pin| pin.name.start_with?(full) }
            end
          else
            result.concat api_map.get_constants(type.namespace, cursor.start_of_constant? ? '' : context_pin.full_context.namespace, *gates)
          end
        else
          type = cursor.chain.base.infer(api_map, block, locals)
          result.concat api_map.get_complex_type_methods(type, block.binder.namespace, cursor.chain.links.length == 1)
          if cursor.chain.links.length == 1
            if cursor.word.start_with?('@@')
              return package_completions(api_map.get_class_variable_pins(context_pin.full_context.namespace))
            elsif cursor.word.start_with?('@')
              return package_completions(api_map.get_instance_variable_pins(block.binder.namespace, block.binder.scope))
            elsif cursor.word.start_with?('$')
              return package_completions(api_map.get_global_variable_pins)
            end
            result.concat locals
            result.concat api_map.get_constants(context_pin.context.namespace, *gates)
            result.concat api_map.get_methods(block.binder.namespace, scope: block.binder.scope, visibility: [:public, :private, :protected])
            result.concat api_map.get_methods('Kernel')
            # result.concat ApiMap.keywords
            result.concat api_map.keyword_pins.to_a
            result.concat yielded_self_pins
          end
        end
        package_completions(result)
      end
    end
  end
end
