require 'set'
require 'flipper'
require 'active_record'

module Flipper
  module Adapters
    class ActiveRecord
      include ::Flipper::Adapter

      # Abstract base class for internal models
      class Model < ::ActiveRecord::Base
        self.abstract_class = true
      end

      # Private: Do not use outside of this adapter.
      class Feature < Model
        self.table_name = [
          Model.table_name_prefix,
          "flipper_features",
          Model.table_name_suffix,
        ].join
      end

      # Private: Do not use outside of this adapter.
      class Gate < Model
        self.table_name = [
          Model.table_name_prefix,
          "flipper_gates",
          Model.table_name_suffix,
        ].join
      end

      # Public: The name of the adapter.
      attr_reader :name

      # Public: Initialize a new ActiveRecord adapter instance.
      #
      # name - The Symbol name for this adapter. Optional (default :active_record)
      # feature_class - The AR class responsible for the features table.
      # gate_class - The AR class responsible for the gates table.
      #
      # Allowing the overriding of name is so you can differentiate multiple
      # instances of this adapter from each other, if, for some reason, that is
      # a thing you do.
      #
      # Allowing the overriding of the default feature/gate classes means you
      # can roll your own tables and what not, if you so desire.
      def initialize(options = {})
        @name = options.fetch(:name, :active_record)
        @feature_class = options.fetch(:feature_class) { Feature }
        @gate_class = options.fetch(:gate_class) { Gate }
      end

      # Public: The set of known features.
      def features
        @feature_class.all.map(&:key).to_set
      end

      # Public: Adds a feature to the set of known features.
      def add(feature)
        # race condition, but add is only used by enable/disable which happen
        # super rarely, so it shouldn't matter in practice
        @feature_class.transaction do
          unless @feature_class.where(key: feature.key).first
            begin
              @feature_class.create! { |f| f.key = feature.key }
            rescue ::ActiveRecord::RecordNotUnique
            end
          end
        end

        true
      end

      # Public: Removes a feature from the set of known features.
      def remove(feature)
        @feature_class.transaction do
          @feature_class.where(key: feature.key).destroy_all
          clear(feature)
        end
        true
      end

      # Public: Clears the gate values for a feature.
      def clear(feature)
        @gate_class.where(feature_key: feature.key).destroy_all
        true
      end

      # Public: Gets the values for all gates for a given feature.
      #
      # Returns a Hash of Flipper::Gate#key => value.
      def get(feature)
        db_gates = @gate_class.where(feature_key: feature.key)
        result_for_feature(feature, db_gates)
      end

      def get_multi(features)
        db_gates = @gate_class.where(feature_key: features.map(&:key))
        grouped_db_gates = db_gates.group_by(&:feature_key)
        result = {}
        features.each do |feature|
          result[feature.key] = result_for_feature(feature, grouped_db_gates[feature.key])
        end
        result
      end

      def get_all
        features = ::Arel::Table.new(@feature_class.table_name.to_sym)
        gates = ::Arel::Table.new(@gate_class.table_name.to_sym)
        rows_query = features.join(gates, Arel::Nodes::OuterJoin)
          .on(features[:key].eq(gates[:feature_key]))
          .project(features[:key].as('feature_key'), gates[:key], gates[:value])
        rows = @feature_class.connection.select_all rows_query
        db_gates = rows.map { |row| @gate_class.new(row) }
        grouped_db_gates = db_gates.group_by(&:feature_key)
        result = Hash.new { |hash, key| hash[key] = default_config }
        features = grouped_db_gates.keys.map { |key| Flipper::Feature.new(key, self) }
        features.each do |feature|
          result[feature.key] = result_for_feature(feature, grouped_db_gates[feature.key])
        end
        result
      end

      # Public: Enables a gate for a given thing.
      #
      # feature - The Flipper::Feature for the gate.
      # gate - The Flipper::Gate to disable.
      # thing - The Flipper::Type being enabled for the gate.
      #
      # Returns true.
      def enable(feature, gate, thing)
        case gate.data_type
        when :boolean
          set(feature, gate, thing, clear: true)
        when :integer
          set(feature, gate, thing)
        when :set
          enable_multi(feature, gate, thing)
        else
          unsupported_data_type gate.data_type
        end

        true
      end

      # Public: Disables a gate for a given thing.
      #
      # feature - The Flipper::Feature for the gate.
      # gate - The Flipper::Gate to disable.
      # thing - The Flipper::Type being disabled for the gate.
      #
      # Returns true.
      def disable(feature, gate, thing)
        case gate.data_type
        when :boolean
          clear(feature)
        when :integer
          set(feature, gate, thing)
        when :set
          @gate_class.where(feature_key: feature.key, key: gate.key, value: thing.value).destroy_all
        else
          unsupported_data_type gate.data_type
        end

        true
      end

      # Private
      def unsupported_data_type(data_type)
        raise "#{data_type} is not supported by this adapter"
      end

      private

      def set(feature, gate, thing, options = {})
        clear_feature = options.fetch(:clear, false)
        @gate_class.transaction do
          clear(feature) if clear_feature
          @gate_class.where(feature_key: feature.key, key: gate.key).destroy_all
          begin
            @gate_class.create! do |g|
              g.feature_key = feature.key
              g.key = gate.key
              g.value = thing.value.to_s
            end
          rescue ::ActiveRecord::RecordNotUnique
            # assume this happened concurrently with the same thing and its fine
            # see https://github.com/jnunemaker/flipper/issues/544
          end
        end

        nil
      end

      def enable_multi(feature, gate, thing)
        @gate_class.create! do |g|
          g.feature_key = feature.key
          g.key = gate.key
          g.value = thing.value.to_s
        end

        nil
      rescue ::ActiveRecord::RecordNotUnique
        # already added so no need move on with life
      end

      def result_for_feature(feature, db_gates)
        db_gates ||= []
        result = {}
        feature.gates.each do |gate|
          result[gate.key] =
            case gate.data_type
            when :boolean
              if detected_db_gate = db_gates.detect { |db_gate| db_gate.key == gate.key.to_s }
                detected_db_gate.value
              end
            when :integer
              if detected_db_gate = db_gates.detect { |db_gate| db_gate.key == gate.key.to_s }
                detected_db_gate.value
              end
            when :set
              db_gates.select { |db_gate| db_gate.key == gate.key.to_s }.map(&:value).to_set
            else
              unsupported_data_type gate.data_type
            end
        end
        result
      end
    end
  end
end

Flipper.configure do |config|
  config.adapter { Flipper::Adapters::ActiveRecord.new }
end
