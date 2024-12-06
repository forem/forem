require 'delegate'
require 'vcr/errors'

module VCR
  # A Cassette wrapper for linking cassettes from another thread
  class LinkedCassette < SimpleDelegator
    # An enumerable lazily wrapping a list of cassettes that a context is using
    class CassetteList
      include Enumerable

      # Creates a new list of context-owned cassettes and linked cassettes
      # @param cassettes [Array] context-owned cassettes
      # @param linked_cassettes [Array] context-unowned (linked) cassettes
      def initialize(cassettes, linked_cassettes)
        @cassettes = cassettes
        @linked_cassettes = linked_cassettes
      end

      # Yields linked cassettes first, and then context-owned cassettes
      def each
        @linked_cassettes.each do |cassette|
          yield wrap(cassette)
        end

        @cassettes.each do |cassette|
          yield cassette
        end
      end

      # Provide last implementation, which is not provided by Enumerable
      def last
        cassette = @cassettes.last
        return cassette if cassette

        cassette = @linked_cassettes.last
        wrap(cassette) if cassette
      end

      # Provide size implementation, which is not provided by Enumerable
      def size
        @cassettes.size + @linked_cassettes.size
      end

    protected
      def wrap(cassette)
        if cassette.linked?
          cassette
        else
          LinkedCassette.new(cassette)
        end
      end
    end

    # Create a new CassetteList
    # @param cassettes [Array] context-owned cassettes
    # @param linked_cassettes [Array] context-unowned (linked) cassettes
    def self.list(cassettes, linked_cassettes)
      CassetteList.new(cassettes, linked_cassettes)
    end

    # Prevents cassette ejection by raising EjectLinkedCassetteError
    def eject(*args)
      raise Errors::EjectLinkedCassetteError,
        "cannot eject a cassette inserted by a parent thread"
    end

    # @return [Boolean] true
    def linked?
      true
    end
  end
end
