require 'addressable/uri'
require 'forwardable'
require 'memoizable'
require 'twitter/null_object'
require 'twitter/utils'

module Twitter
  class Base
    extend Forwardable
    include Memoizable
    include Twitter::Utils
    # @return [Hash]
    attr_reader :attrs
    alias to_h attrs
    alias to_hash to_h

    class << self
      # Define methods that retrieve the value from attributes
      #
      # @param attrs [Array, Symbol]
      def attr_reader(*attrs)
        attrs.each do |attr|
          define_attribute_method(attr)
          define_predicate_method(attr)
        end
      end

      def predicate_attr_reader(*attrs)
        attrs.each do |attr|
          define_predicate_method(attr)
        end
      end

      # Define object methods from attributes
      #
      # @param klass [Symbol]
      # @param key1 [Symbol]
      # @param key2 [Symbol]
      def object_attr_reader(klass, key1, key2 = nil)
        define_attribute_method(key1, klass, key2)
        define_predicate_method(key1)
      end

      # Define URI methods from attributes
      #
      # @param attrs [Array, Symbol]
      def uri_attr_reader(*attrs)
        attrs.each do |uri_key|
          array = uri_key.to_s.split('_')
          index = array.index('uri')
          array[index] = 'url'
          url_key = array.join('_').to_sym
          define_uri_method(uri_key, url_key)
          alias_method(url_key, uri_key)
          define_predicate_method(uri_key, url_key)
          alias_method(:"#{url_key}?", :"#{uri_key}?")
        end
      end

      # Define display_uri attribute methods
      def display_uri_attr_reader
        define_attribute_method(:display_url)
        alias_method(:display_uri, :display_url)
        define_predicate_method(:display_uri, :display_url)
        alias_method(:display_url?, :display_uri?)
      end

      # Dynamically define a method for a URI
      #
      # @param key1 [Symbol]
      # @param key2 [Symbol]
      def define_uri_method(key1, key2)
        define_method(key1) do
          Addressable::URI.parse(@attrs[key2].chomp('#')) unless @attrs[key2].nil?
        end
        memoize(key1)
      end

      # Dynamically define a method for an attribute
      #
      # @param key1 [Symbol]
      # @param klass [Symbol]
      # @param key2 [Symbol]
      def define_attribute_method(key1, klass = nil, key2 = nil)
        define_method(key1) do
          if attr_falsey_or_empty?(key1)
            NullObject.new
          else
            klass.nil? ? @attrs[key1] : Twitter.const_get(klass).new(attrs_for_object(key1, key2))
          end
        end
        memoize(key1)
      end

      # Dynamically define a predicate method for an attribute
      #
      # @param key1 [Symbol]
      # @param key2 [Symbol]
      def define_predicate_method(key1, key2 = key1)
        define_method(:"#{key1}?") do
          !attr_falsey_or_empty?(key2)
        end
        memoize(:"#{key1}?")
      end
    end

    # Initializes a new object
    #
    # @param attrs [Hash]
    # @return [Twitter::Base]
    def initialize(attrs = {})
      @attrs = attrs || {}
    end

    # Fetches an attribute of an object using hash notation
    #
    # @param method [String, Symbol] Message to send to the object
    def [](method)
      warn "#{Kernel.caller.first}: [DEPRECATION] #[#{method.inspect}] is deprecated. Use ##{method} to fetch the value."
      send(method.to_sym)
    rescue NoMethodError
      nil
    end

  private

    def attr_falsey_or_empty?(key)
      !@attrs[key] || @attrs[key].respond_to?(:empty?) && @attrs[key].empty?
    end

    def attrs_for_object(key1, key2 = nil)
      if key2.nil?
        @attrs[key1]
      else
        attrs = @attrs.dup
        attrs.delete(key1).merge(key2 => attrs)
      end
    end
  end
end
