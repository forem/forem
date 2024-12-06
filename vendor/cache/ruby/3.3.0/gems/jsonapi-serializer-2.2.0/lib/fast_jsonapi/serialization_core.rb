# frozen_string_literal: true

require 'active_support/concern'
require 'digest/sha1'

module FastJsonapi
  MandatoryField = Class.new(StandardError)

  module SerializationCore
    extend ActiveSupport::Concern

    included do
      class << self
        attr_accessor :attributes_to_serialize,
                      :relationships_to_serialize,
                      :cachable_relationships_to_serialize,
                      :uncachable_relationships_to_serialize,
                      :transform_method,
                      :record_type,
                      :record_id,
                      :cache_store_instance,
                      :cache_store_options,
                      :data_links,
                      :meta_to_serialize
      end
    end

    class_methods do
      def id_hash(id, record_type, default_return = false)
        if id.present?
          { id: id.to_s, type: record_type }
        else
          default_return ? { id: nil, type: record_type } : nil
        end
      end

      def links_hash(record, params = {})
        data_links.each_with_object({}) do |(_k, link), hash|
          link.serialize(record, params, hash)
        end
      end

      def attributes_hash(record, fieldset = nil, params = {})
        attributes = attributes_to_serialize
        attributes = attributes.slice(*fieldset) if fieldset.present?
        attributes = {} if fieldset == []

        attributes.each_with_object({}) do |(_k, attribute), hash|
          attribute.serialize(record, params, hash)
        end
      end

      def relationships_hash(record, relationships = nil, fieldset = nil, includes_list = nil, params = {})
        relationships = relationships_to_serialize if relationships.nil?
        relationships = relationships.slice(*fieldset) if fieldset.present?
        relationships = {} if fieldset == []

        relationships.each_with_object({}) do |(key, relationship), hash|
          included = includes_list.present? && includes_list.include?(key)
          relationship.serialize(record, included, params, hash)
        end
      end

      def meta_hash(record, params = {})
        FastJsonapi.call_proc(meta_to_serialize, record, params)
      end

      def record_hash(record, fieldset, includes_list, params = {})
        if cache_store_instance
          cache_opts = record_cache_options(cache_store_options, fieldset, includes_list, params)
          record_hash = cache_store_instance.fetch(record, **cache_opts) do
            temp_hash = id_hash(id_from_record(record, params), record_type, true)
            temp_hash[:attributes] = attributes_hash(record, fieldset, params) if attributes_to_serialize.present?
            temp_hash[:relationships] = relationships_hash(record, cachable_relationships_to_serialize, fieldset, includes_list, params) if cachable_relationships_to_serialize.present?
            temp_hash[:links] = links_hash(record, params) if data_links.present?
            temp_hash
          end
          record_hash[:relationships] = (record_hash[:relationships] || {}).merge(relationships_hash(record, uncachable_relationships_to_serialize, fieldset, includes_list, params)) if uncachable_relationships_to_serialize.present?
        else
          record_hash = id_hash(id_from_record(record, params), record_type, true)
          record_hash[:attributes] = attributes_hash(record, fieldset, params) if attributes_to_serialize.present?
          record_hash[:relationships] = relationships_hash(record, nil, fieldset, includes_list, params) if relationships_to_serialize.present?
          record_hash[:links] = links_hash(record, params) if data_links.present?
        end

        record_hash[:meta] = meta_hash(record, params) if meta_to_serialize.present?
        record_hash
      end

      # Cache options helper. Use it to adapt cache keys/rules.
      #
      # If a fieldset is specified, it modifies the namespace to include the
      # fields from the fieldset.
      #
      # @param options [Hash] default cache options
      # @param fieldset [Array, nil] passed fieldset values
      # @param includes_list [Array, nil] passed included values
      # @param params [Hash] the serializer params
      #
      # @return [Hash] processed options hash
      # rubocop:disable Lint/UnusedMethodArgument
      def record_cache_options(options, fieldset, includes_list, params)
        return options unless fieldset

        options = options ? options.dup : {}
        options[:namespace] ||= 'jsonapi-serializer'

        fieldset_key = fieldset.join('_')

        # Use a fixed-length fieldset key if the current length is more than
        # the length of a SHA1 digest
        if fieldset_key.length > 40
          fieldset_key = Digest::SHA1.hexdigest(fieldset_key)
        end

        options[:namespace] = "#{options[:namespace]}-fieldset:#{fieldset_key}"
        options
      end
      # rubocop:enable Lint/UnusedMethodArgument

      def id_from_record(record, params)
        return FastJsonapi.call_proc(record_id, record, params) if record_id.is_a?(Proc)
        return record.send(record_id) if record_id
        raise MandatoryField, 'id is a mandatory field in the jsonapi spec' unless record.respond_to?(:id)

        record.id
      end

      # It chops out the root association (first part) from each include.
      #
      # It keeps an unique list and collects all of the rest of the include
      # value to hand it off to the next related to include serializer.
      #
      # This method will turn that include array into a Hash that looks like:
      #
      #   {
      #       authors: Set.new([
      #         'books',
      #         'books.genre',
      #         'books.genre.books',
      #         'books.genre.books.authors',
      #         'books.genre.books.genre'
      #       ]),
      #       genre: Set.new(['books'])
      #   }
      #
      # Because the serializer only cares about the root associations
      # included, it only needs the first segment of each include
      # (for books, it's the "authors" and "genre") and it doesn't need to
      # waste cycles parsing the rest of the include value. That will be done
      # by the next serializer in line.
      #
      # @param includes_list [List] to be parsed
      # @return [Hash]
      def parse_includes_list(includes_list)
        includes_list.each_with_object({}) do |include_item, include_sets|
          include_base, include_remainder = include_item.to_s.split('.', 2)
          include_sets[include_base.to_sym] ||= Set.new
          include_sets[include_base.to_sym] << include_remainder if include_remainder
        end
      end

      # includes handler
      def get_included_records(record, includes_list, known_included_objects, fieldsets, params = {})
        return unless includes_list.present?
        return [] unless relationships_to_serialize

        includes_list = parse_includes_list(includes_list)

        includes_list.each_with_object([]) do |include_item, included_records|
          relationship_item = relationships_to_serialize[include_item.first]

          next unless relationship_item&.include_relationship?(record, params)

          included_objects = Array(relationship_item.fetch_associated_object(record, params))
          next if included_objects.empty?

          static_serializer = relationship_item.static_serializer
          static_record_type = relationship_item.static_record_type

          included_objects.each do |inc_obj|
            serializer = static_serializer || relationship_item.serializer_for(inc_obj, params)
            record_type = static_record_type || serializer.record_type

            if include_item.last.any?
              serializer_records = serializer.get_included_records(inc_obj, include_item.last, known_included_objects, fieldsets, params)
              included_records.concat(serializer_records) unless serializer_records.empty?
            end

            code = "#{record_type}_#{serializer.id_from_record(inc_obj, params)}"
            next if known_included_objects.include?(code)

            known_included_objects << code

            included_records << serializer.record_hash(inc_obj, fieldsets[record_type], includes_list, params)
          end
        end
      end
    end
  end
end
