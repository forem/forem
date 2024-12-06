# frozen_string_literal: true

require 'yard'
require 'yard-solargraph'
require 'set'

module Solargraph
  # An index of pins and other ApiMap-related data for a Source.
  #
  class SourceMap
    autoload :Mapper,        'solargraph/source_map/mapper'
    autoload :Clip,          'solargraph/source_map/clip'
    autoload :Completion,    'solargraph/source_map/completion'

    # @return [Source]
    attr_reader :source

    # @return [Array<Pin::Base>]
    attr_reader :pins

    # @return [Array<Pin::Base>]
    attr_reader :locals

    # @param source [Source]
    # @param pins [Array<Pin::Base>]
    # @param locals [Array<Pin::Base>]
    def initialize source, pins, locals
      # HACK: Keep the library from changing this
      @source = source.dup
      @pins = pins
      @locals = locals
      environ.merge Convention.for_local(self) unless filename.nil?
      @pin_class_hash = pins.to_set.classify(&:class).transform_values(&:to_a)
      @pin_select_cache = {}
    end

    def pins_by_class klass
      @pin_select_cache[klass] ||= @pin_class_hash.select { |key, _| key <= klass }.values.flatten
    end

    def rebindable_method_names
      @rebindable_method_names ||= pins_by_class(Pin::Method)
        .select { |pin| pin.comments && pin.comments.include?('@yieldself') }
        .map(&:name)
        .to_set
    end

    # @return [String]
    def filename
      source.filename
    end

    # @return [String]
    def code
      source.code
    end

    # @return [Array<Pin::Reference::Require>]
    def requires
      pins_by_class(Pin::Reference::Require)
    end

    # @return [Environ]
    def environ
      @environ ||= Environ.new
    end

    # @return [Array<Pin::Base>]
    def document_symbols
      @document_symbols ||= pins.select { |pin|
        pin.path && !pin.path.empty?
      }
    end

    # @param query [String]
    # @return [Array<Pin::Base>]
    def query_symbols query
      Pin::Search.new(document_symbols, query).results
    end

    # @param position [Position]
    # @return [Source::Cursor]
    def cursor_at position
      Source::Cursor.new(source, position)
    end

    # @param path [String]
    # @return [Pin::Base]
    def first_pin path
      pins.select { |p| p.path == path }.first
    end

    # @param location [Solargraph::Location]
    # @return [Array<Solargraph::Pin::Base>]
    def locate_pins location
      # return nil unless location.start_with?("#{filename}:")
      (pins + locals).select { |pin| pin.location == location }
    end

    def locate_named_path_pin line, character
      _locate_pin line, character, Pin::Namespace, Pin::Method
    end

    def locate_block_pin line, character
      _locate_pin line, character, Pin::Namespace, Pin::Method, Pin::Block
    end

    # @param other_map [SourceMap]
    # @return [Boolean]
    def try_merge! other_map
      return false if pins.length != other_map.pins.length || locals.length != other_map.locals.length || requires.map(&:name).uniq.sort != other_map.requires.map(&:name).uniq.sort
      pins.each_index do |i|
        return false unless pins[i].try_merge!(other_map.pins[i])
      end
      locals.each_index do |i|
        return false unless locals[i].try_merge!(other_map.locals[i])
      end
      @source = other_map.source
      true
    end

    # @param name [String]
    # @return [Array<Location>]
    def references name
      source.references name
    end

    # @param location [Location]
    # @return [Array<Pin::LocalVariable>]
    def locals_at(location)
      return [] if location.filename != filename
      closure = locate_named_path_pin(location.range.start.line, location.range.start.character)
      locals.select { |pin| pin.visible_at?(closure, location) }
    end

    class << self
      # @param filename [String]
      # @return [SourceMap]
      def load filename
        source = Solargraph::Source.load(filename)
        SourceMap.map(source)
      end

      # @param code [String]
      # @param filename [String, nil]
      # @return [SourceMap]
      def load_string code, filename = nil
        source = Solargraph::Source.load_string(code, filename)
        SourceMap.map(source)
      end

      # @param source [Source]
      # @return [SourceMap]
      def map source
        result = SourceMap::Mapper.map(source)
        new(source, *result)
      end
    end

    private

    # @param line [Integer]
    # @param character [Integer]
    # @param klasses [Array<Class>]
    # @return [Pin::Base]
    def _locate_pin line, character, *klasses
      position = Position.new(line, character)
      found = nil
      pins.each do |pin|
        # @todo Attribute pins should not be treated like closures, but
        #   there's probably a better way to handle it
        next if pin.is_a?(Pin::Method) && pin.attribute?
        found = pin if (klasses.empty? || klasses.any? { |kls| pin.is_a?(kls) } ) && pin.location.range.contain?(position)
        break if pin.location.range.start.line > line
      end
      # Assuming the root pin is always valid
      found || pins.first
    end
  end
end
