# frozen_string_literal: true

module Modis
  module Index
    def self.included(base)
      base.extend ClassMethods
      base.instance_eval do
        bootstrap_indexes
      end
    end

    module ClassMethods
      def bootstrap_indexes(parent = nil)
        class << self
          attr_accessor :indexed_attributes
        end

        self.indexed_attributes = parent ? parent.indexed_attributes.dup : []
      end

      def index(attribute)
        attribute = attribute.to_s
        raise IndexError, "No such attribute '#{attribute}'" unless attributes.key?(attribute)

        indexed_attributes << attribute
      end

      def where(query)
        raise IndexError, 'Queries using multiple indexes is not currently supported.' if query.keys.size > 1

        attribute, value = query.first
        ids = index_for(attribute, value)
        return [] if ids.empty?

        find_all(ids)
      end

      def index_for(attribute, value)
        Modis.with_connection do |redis|
          key = index_key(attribute, value)
          redis.smembers(key).map(&:to_i)
        end
      end

      def index_key(attribute, value)
        "#{absolute_namespace}:index:#{attribute}:#{value.inspect}"
      end
    end

    private

    def indexed_attributes
      self.class.indexed_attributes
    end

    def index_key(attribute, value)
      self.class.index_key(attribute, value)
    end

    def add_to_indexes(redis)
      return if indexed_attributes.empty?

      indexed_attributes.each do |attribute|
        key = index_key(attribute, read_attribute(attribute))
        redis.sadd(key, id)
      end
    end

    def remove_from_indexes(redis)
      return if indexed_attributes.empty?

      indexed_attributes.each do |attribute|
        key = index_key(attribute, read_attribute(attribute))
        redis.srem(key, id)
      end
    end

    def update_indexes(redis)
      return if indexed_attributes.empty?

      (changes.keys & indexed_attributes).each do |attribute|
        old_value, new_value = changes[attribute]
        old_key = index_key(attribute, old_value)
        new_key = index_key(attribute, new_value)
        redis.smove(old_key, new_key, id)
      end
    end
  end
end
