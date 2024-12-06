require 'thread'

module Flipper
  # Internal: Used to store registry of groups by name.
  class Registry
    include Enumerable

    class Error < StandardError; end
    class DuplicateKey < Error; end

    class KeyNotFound < Error
      # Public: The key that was not found
      attr_reader :key

      def initialize(key)
        @key = key
        super("Key #{key.inspect} not found")
      end
    end

    def initialize(source = {})
      @mutex = Mutex.new
      @source = source
    end

    def keys
      @mutex.synchronize { @source.keys }
    end

    def values
      @mutex.synchronize { @source.values }
    end

    def add(key, value)
      key = key.to_sym

      @mutex.synchronize do
        if @source[key]
          raise DuplicateKey, "#{key} is already registered"
        else
          @source[key] = value
        end
      end
    end

    def get(key)
      key = key.to_sym
      @mutex.synchronize do
        @source[key]
      end
    end

    def key?(key)
      key = key.to_sym
      @mutex.synchronize do
        @source.key?(key)
      end
    end

    def each(&block)
      @mutex.synchronize { @source.dup }.each(&block)
    end

    def clear
      @mutex.synchronize { @source.clear }
    end
  end
end
