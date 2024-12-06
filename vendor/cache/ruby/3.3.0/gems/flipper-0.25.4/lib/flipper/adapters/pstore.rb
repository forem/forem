require 'pstore'
require 'set'
require 'flipper'

module Flipper
  module Adapters
    # Public: Adapter based on Ruby's pstore database. Perfect for when a local
    # file is good enough for storing features.
    class PStore
      include ::Flipper::Adapter

      FeaturesKey = :flipper_features

      # Public: The name of the adapter.
      attr_reader :name

      # Public: The path to where the file is stored.
      attr_reader :path

      # Public
      def initialize(path = 'flipper.pstore', thread_safe = true)
        @name = :pstore
        @path = path
        @store = ::PStore.new(path, thread_safe)
      end

      # Public: The set of known features.
      def features
        @store.transaction do
          read_feature_keys
        end
      end

      # Public: Adds a feature to the set of known features.
      def add(feature)
        @store.transaction do
          set_add FeaturesKey, feature.key
        end
        true
      end

      # Public: Removes a feature from the set of known features and clears
      # all the values for the feature.
      def remove(feature)
        @store.transaction do
          set_delete FeaturesKey, feature.key
          clear_gates(feature)
        end
        true
      end

      # Public: Clears all the gate values for a feature.
      def clear(feature)
        @store.transaction do
          clear_gates(feature)
        end
        true
      end

      # Public
      def get(feature)
        @store.transaction do
          result_for_feature(feature)
        end
      end

      def get_multi(features)
        @store.transaction do
          read_many_features(features)
        end
      end

      def get_all
        @store.transaction do
          features = read_feature_keys.map { |key| Flipper::Feature.new(key, self) }
          read_many_features(features)
        end
      end

      # Public
      def enable(feature, gate, thing)
        @store.transaction do
          case gate.data_type
          when :boolean
            clear_gates(feature)
            write key(feature, gate), thing.value.to_s
          when :integer
            write key(feature, gate), thing.value.to_s
          when :set
            set_add key(feature, gate), thing.value.to_s
          else
            raise "#{gate} is not supported by this adapter yet"
          end
        end

        true
      end

      # Public
      def disable(feature, gate, thing)
        case gate.data_type
        when :boolean
          clear(feature)
        when :integer
          @store.transaction do
            write key(feature, gate), thing.value.to_s
          end
        when :set
          @store.transaction do
            set_delete key(feature, gate), thing.value.to_s
          end
        else
          raise "#{gate} is not supported by this adapter yet"
        end

        true
      end

      # Public
      def inspect
        attributes = [
          "name=#{@name.inspect}",
          "path=#{@path.inspect}",
          "store=#{@store}",
        ]
        "#<#{self.class.name}:#{object_id} #{attributes.join(', ')}>"
      end

      private

      def clear_gates(feature)
        feature.gates.each do |gate|
          delete key(feature, gate)
        end
      end

      def read_feature_keys
        set_members FeaturesKey
      end

      def read_many_features(features)
        result = {}
        features.each do |feature|
          result[feature.key] = result_for_feature(feature)
        end
        result
      end

      def result_for_feature(feature)
        result = {}

        feature.gates.each do |gate|
          result[gate.key] =
            case gate.data_type
            when :boolean, :integer
              read key(feature, gate)
            when :set
              set_members key(feature, gate)
            else
              raise "#{gate} is not supported by this adapter yet"
            end
        end

        result
      end

      # Private
      def key(feature, gate)
        "#{feature.key}/#{gate.key}"
      end

      # Private
      def read(key)
        @store[key.to_s]
      end

      # Private
      def write(key, value)
        @store[key.to_s] = value.to_s
      end

      # Private
      def delete(key)
        @store.delete(key.to_s)
      end

      # Private
      def set_add(key, value)
        set_members(key) do |members|
          members.add(value.to_s)
        end
      end

      # Private
      def set_delete(key, value)
        set_members(key) do |members|
          members.delete(value.to_s)
        end
      end

      # Private
      def set_members(key)
        key = key.to_s

        @store[key] ||= Set.new

        if block_given?
          yield @store[key]
        else
          @store[key]
        end
      end
    end
  end
end

Flipper.configure do |config|
  config.adapter { Flipper::Adapters::PStore.new }
end
