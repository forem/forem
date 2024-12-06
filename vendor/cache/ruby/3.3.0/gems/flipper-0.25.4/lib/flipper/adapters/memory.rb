require 'set'

module Flipper
  module Adapters
    # Public: Adapter for storing everything in memory.
    # Useful for tests/specs.
    class Memory
      include ::Flipper::Adapter

      FeaturesKey = :features

      # Public: The name of the adapter.
      attr_reader :name

      # Public
      def initialize(source = nil)
        @source = source || {}
        @name = :memory
      end

      # Public: The set of known features.
      def features
        @source.keys.to_set
      end

      # Public: Adds a feature to the set of known features.
      def add(feature)
        @source[feature.key] ||= default_config
        true
      end

      # Public: Removes a feature from the set of known features and clears
      # all the values for the feature.
      def remove(feature)
        @source.delete(feature.key)
        true
      end

      # Public: Clears all the gate values for a feature.
      def clear(feature)
        @source[feature.key] = default_config
        true
      end

      # Public
      def get(feature)
        @source[feature.key] || default_config
      end

      def get_multi(features)
        result = {}
        features.each do |feature|
          result[feature.key] = @source[feature.key] || default_config
        end
        result
      end

      def get_all
        @source
      end

      # Public
      def enable(feature, gate, thing)
        @source[feature.key] ||= default_config

        case gate.data_type
        when :boolean
          clear(feature)
          @source[feature.key][gate.key] = thing.value.to_s
        when :integer
          @source[feature.key][gate.key] = thing.value.to_s
        when :set
          @source[feature.key][gate.key] << thing.value.to_s
        else
          raise "#{gate} is not supported by this adapter yet"
        end

        true
      end

      # Public
      def disable(feature, gate, thing)
        @source[feature.key] ||= default_config

        case gate.data_type
        when :boolean
          clear(feature)
        when :integer
          @source[feature.key][gate.key] = thing.value.to_s
        when :set
          @source[feature.key][gate.key].delete thing.value.to_s
        else
          raise "#{gate} is not supported by this adapter yet"
        end

        true
      end

      # Public
      def inspect
        attributes = [
          'name=:memory',
          "source=#{@source.inspect}",
        ]
        "#<#{self.class.name}:#{object_id} #{attributes.join(', ')}>"
      end
    end
  end
end
