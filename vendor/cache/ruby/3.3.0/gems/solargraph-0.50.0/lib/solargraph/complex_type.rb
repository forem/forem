# frozen_string_literal: true

module Solargraph
  # A container for type data based on YARD type tags.
  #
  class ComplexType
    # @!parse
    #   include TypeMethods

    autoload :TypeMethods, 'solargraph/complex_type/type_methods'
    autoload :UniqueType,  'solargraph/complex_type/unique_type'

    # @param types [Array<UniqueType>]
    def initialize types = [UniqueType::UNDEFINED]
      @items = types.uniq(&:to_s)
    end

    # @param api_map [ApiMap]
    # @param context [String]
    # @return [ComplexType]
    def qualify api_map, context = ''
      types = @items.map do |t|
        next t if ['Boolean', 'nil', 'void', 'undefined'].include?(t.name)
        t.qualify api_map, context
      end
      ComplexType.new(types)
    end

    def first
      @items.first
    end

    def to_rbs
      ((@items.length > 1 ? '(' : '') + @items.map do |item|
        "#{item.namespace}#{item.parameters? ? "[#{item.subtypes.map { |s| s.to_rbs }.join(', ')}]" : ''}"
      end.join(' | ') + (@items.length > 1 ? ')' : '')).gsub(/undefined/, 'untyped')
    end

    def map &block
      @items.map &block
    end

    # @yieldparam [UniqueType]
    # @return [Array]
    def each &block
      @items.each &block
    end

    # @yieldparam [UniqueType]
    # @return [Enumerator<UniqueType>]
    def each_unique_type &block
      return enum_for(__method__) unless block_given?

      @items.each do |item|
        item.each_unique_type &block
      end
    end

    def length
      @items.length
    end

    def [](index)
      @items[index]
    end

    def select &block
      @items.select &block
    end
    def namespace
      # cache this attr for high frequency call
      @namespace ||= method_missing(:namespace).to_s
    end

    def method_missing name, *args, &block
      return if @items.first.nil?
      return @items.first.send(name, *args, &block) if respond_to_missing?(name)
      super
    end

    def respond_to_missing?(name, include_private = false)
      TypeMethods.public_instance_methods.include?(name) || super
    end

    def to_s
      map(&:tag).join(', ')
    end

    def all? &block
      @items.all? &block
    end

    def any? &block
      @items.compact.any? &block
    end

    def selfy?
      @items.any?(&:selfy?)
    end

    def parameterized?
      any?(&:parameterized?)
    end

    def resolve_parameters definitions, context
      result = @items.map { |i| i.resolve_parameters(definitions, context) }
      ComplexType.parse(*result.map(&:tag))
    end

    # @param dst [String]
    # @return [ComplexType]
    def self_to dst
      return self unless selfy?
      red = reduce_class(dst)
      result = @items.map { |i| i.self_to red }
      ComplexType.parse(*result.map(&:to_s))
    end

    def nullable?
      @items.any?(&:nil_type?)
    end

    def all_params
      @items.first.all_params || []
    end

    private

    # @todo This is a quick and dirty hack that forces `self` keywords
    #   to reference an instance of their class and never the class itself.
    #   This behavior may change depending on which result is expected
    #   from YARD conventions. See https://github.com/lsegal/yard/issues/1257
    # @param dst [String]
    # @return [String]
    def reduce_class dst
      while dst =~ /^(Class|Module)\<(.*?)\>$/
        dst = dst.sub(/^(Class|Module)\</, '').sub(/\>$/, '')
      end
      dst
    end

    class << self
      # Parse type strings into a ComplexType.
      #
      # @example
      #   ComplexType.parse 'String', 'Foo', 'nil' #=> [String, Foo, nil]
      #
      # @note
      #   The `partial` parameter is used to indicate that the method is
      #   receiving a string that will be used inside another ComplexType.
      #   It returns arrays of ComplexTypes instead of a single cohesive one.
      #   Consumers should not need to use this parameter; it should only be
      #   used internally.
      #
      # @param *strings [Array<String>] The type definitions to parse
      # @param partial [Boolean] True if the string is part of a another type
      # @return [ComplexType, Array, nil]
      def parse *strings, partial: false
        @cache ||= {}
        unless partial
          cached = @cache[strings]
          return cached unless cached.nil?
        end
        types = []
        key_types = nil
        strings.each do |type_string|
          point_stack = 0
          curly_stack = 0
          paren_stack = 0
          base = String.new
          subtype_string = String.new
          type_string&.each_char do |char|
            if char == '='
              #raise ComplexTypeError, "Invalid = in type #{type_string}" unless curly_stack > 0
            elsif char == '<'
              point_stack += 1
            elsif char == '>'
              if subtype_string.end_with?('=') && curly_stack > 0
                subtype_string += char
              elsif base.end_with?('=')
                raise ComplexTypeError, "Invalid hash thing" unless key_types.nil?
                # types.push ComplexType.new([UniqueType.new(base[0..-2].strip)])
                types.push UniqueType.new(base[0..-2].strip)
                key_types = types
                types = []
                base.clear
                subtype_string.clear
                next
              else
                raise ComplexTypeError, "Invalid close in type #{type_string}" if point_stack == 0
                point_stack -= 1
                subtype_string += char
              end
              next
            elsif char == '{'
              curly_stack += 1
            elsif char == '}'
              curly_stack -= 1
              subtype_string += char
              raise ComplexTypeError, "Invalid close in type #{type_string}" if curly_stack < 0
              next
            elsif char == '('
              paren_stack += 1
            elsif char == ')'
              paren_stack -= 1
              subtype_string += char if paren_stack == 0
              raise ComplexTypeError, "Invalid close in type #{type_string}" if paren_stack < 0
              next
            elsif char == ',' && point_stack == 0 && curly_stack == 0 && paren_stack == 0
              # types.push ComplexType.new([UniqueType.new(base.strip, subtype_string.strip)])
              types.push UniqueType.new(base.strip, subtype_string.strip)
              base.clear
              subtype_string.clear
              next
            end
            if point_stack == 0 && curly_stack == 0 && paren_stack == 0
              base.concat char
            else
              subtype_string.concat char
            end
          end
          raise ComplexTypeError, "Unclosed subtype in #{type_string}" if point_stack != 0 || curly_stack != 0 || paren_stack != 0
          # types.push ComplexType.new([UniqueType.new(base, subtype_string)])
          types.push UniqueType.new(base.strip, subtype_string.strip)
        end
        unless key_types.nil?
          raise ComplexTypeError, "Invalid use of key/value parameters" unless partial
          return key_types if types.empty?
          return [key_types, types]
        end
        result = partial ? types : ComplexType.new(types)
        @cache[strings] = result unless partial
        result
      end

      # @param strings [Array<String>]
      # @return [ComplexType]
      def try_parse *strings
        parse *strings
      rescue ComplexTypeError => e
        Solargraph.logger.info "Error parsing complex type: #{e.message}"
        ComplexType::UNDEFINED
      end
    end

    VOID = ComplexType.parse('void')
    UNDEFINED = ComplexType.parse('undefined')
    SYMBOL = ComplexType.parse('Symbol')
    ROOT = ComplexType.parse('Class<>')
    NIL = ComplexType.parse('nil')
    SELF = ComplexType.parse('self')
    BOOLEAN = ComplexType.parse('Boolean')
  end
end
