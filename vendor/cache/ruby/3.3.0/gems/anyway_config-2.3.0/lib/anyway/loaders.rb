# frozen_string_literal: true

module Anyway
  using RubyNext

  module Loaders
    class Registry
      attr_reader :registry

      def initialize
        @registry = []
      end

      def prepend(id, handler = nil, &block)
        handler ||= block
        insert_at(0, id, handler)
      end

      def append(id, handler = nil, &block)
        handler ||= block
        insert_at(registry.size, id, handler)
      end

      def insert_before(another_id, id, handler = nil, &block)
        ind = registry.find_index { |(hid, _)| hid == another_id }
        raise ArgumentError, "Loader with ID #{another_id} hasn't been registered" if ind.nil?

        handler ||= block
        insert_at(ind, id, handler)
      end

      def insert_after(another_id, id, handler = nil, &block)
        ind = registry.find_index { |(hid, _)| hid == another_id }
        raise ArgumentError, "Loader with ID #{another_id} hasn't been registered" if ind.nil?

        handler ||= block
        insert_at(ind + 1, id, handler)
      end

      def override(id, handler)
        find(id).then do |id_to_handler|
          raise ArgumentError, "Loader with ID #{id} hasn't been registered" if id_to_handler.nil?
          id_to_handler[1] = handler
        end
      end

      def delete(id)
        find(id).then do |id_to_handler|
          raise ArgumentError, "Loader with ID #{id} hasn't been registered" if id_to_handler.nil?
          registry.delete id_to_handler
        end
      end

      def each(&block)
        registry.each(&block)
      end

      def freeze() = registry.freeze

      private

      def insert_at(index, id, handler)
        raise ArgumentError, "Loader with ID #{id} has been already registered" unless find(id).nil?

        registry.insert(index, [id, handler])
      end

      def find(id)
        registry.find { |(hid, _)| hid == id }
      end
    end
  end
end

require "anyway/loaders/base"
require "anyway/loaders/yaml"
require "anyway/loaders/env"
