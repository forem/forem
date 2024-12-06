# frozen_string_literal: true

module Solargraph
  module Pin
    # The base class for map pins.
    #
    class Base
      include Common
      include Conversions
      include Documenting

      # @return [YARD::CodeObjects::Base]
      attr_reader :code_object

      # @return [Solargraph::Location]
      attr_reader :location

      # @return [String]
      attr_reader :name

      # @return [String]
      attr_reader :path

      # @return [::Symbol]
      attr_accessor :source

      # @param location [Solargraph::Location, nil]
      # @param kind [Integer]
      # @param closure [Solargraph::Pin::Closure, nil]
      # @param name [String]
      # @param comments [String]
      def initialize location: nil, closure: nil, name: '', comments: ''
        @location = location
        @closure = closure
        @name = name
        @comments = comments
      end

      # @return [String]
      def comments
        @comments ||= ''
      end

      # @return [String, nil]
      def filename
        return nil if location.nil?
        location.filename
      end

      # @return [Integer]
      def completion_item_kind
        LanguageServer::CompletionItemKinds::KEYWORD
      end

      # @return [Integer, nil]
      def symbol_kind
        nil
      end

      def to_s
        name.to_s
      end

      # @return [Boolean]
      def variable?
        false
      end

      # Pin equality is determined using the #nearly? method and also
      # requiring both pins to have the same location.
      #
      def == other
        return false unless nearly? other
        comments == other.comments and location == other.location
      end

      # True if the specified pin is a near match to this one. A near match
      # indicates that the pins contain mostly the same data. Any differences
      # between them should not have an impact on the API surface.
      #
      # @param other [Solargraph::Pin::Base, Object]
      # @return [Boolean]
      def nearly? other
        self.class == other.class &&
          name == other.name &&
          (closure == other.closure || (closure && closure.nearly?(other.closure))) &&
          (comments == other.comments ||
            (((maybe_directives? == false && other.maybe_directives? == false) || compare_directives(directives, other.directives)) &&
            compare_docstring_tags(docstring, other.docstring))
          )
      end

      # The pin's return type.
      #
      # @return [ComplexType]
      def return_type
        @return_type ||= ComplexType::UNDEFINED
      end

      # @return [YARD::Docstring]
      def docstring
        parse_comments unless defined?(@docstring)
        @docstring ||= Solargraph::Source.parse_docstring('').to_docstring
      end

      # @return [Array<YARD::Tags::Directive>]
      def directives
        parse_comments unless defined?(@directives)
        @directives
      end

      # @return [Array<YARD::Tags::MacroDirective>]
      def macros
        @macros ||= collect_macros
      end

      # Perform a quick check to see if this pin possibly includes YARD
      # directives. This method does not require parsing the comments.
      #
      # After the comments have been parsed, this method will return false if
      # no directives were found, regardless of whether it previously appeared
      # possible.
      #
      # @return [Boolean]
      def maybe_directives?
        return !@directives.empty? if defined?(@directives)
        @maybe_directives ||= comments.include?('@!')
      end

      # @return [Boolean]
      def deprecated?
        @deprecated ||= docstring.has_tag?('deprecated')
      end

      # Get a fully qualified type from the pin's return type.
      #
      # The relative type is determined from YARD documentation (@return,
      # @param, @type, etc.) and its namespaces are fully qualified using the
      # provided ApiMap.
      #
      # @param api_map [ApiMap]
      # @return [ComplexType]
      def typify api_map
        return_type.qualify(api_map, namespace)
      end

      # Infer the pin's return type via static code analysis.
      #
      # @param api_map [ApiMap]
      # @return [ComplexType]
      def probe api_map
        typify api_map
      end

      # @deprecated Use #typify and/or #probe instead
      # @param api_map [ApiMap]
      # @return [ComplexType]
      def infer api_map
        Solargraph::Logging.logger.warn "WARNING: Pin #infer methods are deprecated. Use #typify or #probe instead."
        type = typify(api_map)
        return type unless type.undefined?
        probe api_map
      end

      # Try to merge data from another pin. Merges are only possible if the
      # pins are near matches (see the #nearly? method). The changes should
      # not have any side effects on the API surface.
      #
      # @param pin [Pin::Base] The pin to merge into this one
      # @return [Boolean] True if the pins were merged
      def try_merge! pin
        return false unless nearly?(pin)
        @location = pin.location
        @closure = pin.closure
        return true if comments == pin.comments
        @comments = pin.comments
        @docstring = pin.docstring
        @return_type = pin.return_type
        @documentation = nil
        @deprecated = nil
        reset_conversions
        true
      end

      def proxied?
        @proxied ||= false
      end

      def probed?
        @probed ||= false
      end

      # @param api_map [ApiMap]
      # @return [self]
      def realize api_map
        return self if return_type.defined?
        type = typify(api_map)
        return proxy(type) if type.defined?
        type = probe(api_map)
        return self if type.undefined?
        result = proxy(type)
        result.probed = true
        result
      end

      # Return a proxy for this pin with the specified return type. Other than
      # the return type and the #proxied? setting, the proxy should be a clone
      # of the original.
      #
      # @param return_type [ComplexType]
      # @return [self]
      def proxy return_type
        result = dup
        result.return_type = return_type
        result.proxied = true
        result
      end

      def identity
        @identity ||= "#{closure.context.namespace}|#{name}"
      end

      def inspect
        "#<#{self.class} `#{self.path}` at #{self.location.inspect}>"
      end

      protected

      # @return [Boolean]
      attr_writer :probed

      # @return [Boolean]
      attr_writer :proxied

      # @return [ComplexType]
      attr_writer :return_type

      private

      # @return [void]
      def parse_comments
        # HACK: Avoid a NoMethodError on nil with empty overload tags
        if comments.nil? || comments.empty? || comments.strip.end_with?('@overload')
          @docstring = nil
          @directives = []
        else
          # HACK: Pass a dummy code object to the parser for plugins that
          # expect it not to be nil
          parse = Solargraph::Source.parse_docstring(comments)
          @docstring = parse.to_docstring
          @directives = parse.directives
        end
      end

      # True if two docstrings have the same tags, regardless of any other
      # differences.
      #
      # @param d1 [YARD::Docstring]
      # @param d2 [YARD::Docstring]
      # @return [Boolean]
      def compare_docstring_tags d1, d2
        return false if d1.tags.length != d2.tags.length
        d1.tags.each_index do |i|
          return false unless compare_tags(d1.tags[i], d2.tags[i])
        end
        true
      end

      # @param dir1 [Array<YARD::Tags::Directive>]
      # @param dir2 [Array<YARD::Tags::Directive>]
      # @return [Boolean]
      def compare_directives dir1, dir2
        return false if dir1.length != dir2.length
        dir1.each_index do |i|
          return false unless compare_tags(dir1[i].tag, dir2[i].tag)
        end
        true
      end

      # @param tag1 [YARD::Tags::Tag]
      # @param tag2 [YARD::Tags::Tag]
      # @return [Boolean]
      def compare_tags tag1, tag2
        tag1.class == tag2.class &&
          tag1.tag_name == tag2.tag_name &&
          tag1.text == tag2.text &&
          tag1.name == tag2.name &&
          tag1.types == tag2.types
      end

      # @return [Array<YARD::Tags::Handlers::Directive>]
      def collect_macros
        return [] unless maybe_directives?
        parse = Solargraph::Source.parse_docstring(comments)
        parse.directives.select{ |d| d.tag.tag_name == 'macro' }
      end
    end
  end
end
