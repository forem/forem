require "flipper/actor"
require "flipper/gate_values"

module Flipper
  module Adapters
    class Sync
      # Internal: Given a feature, local gate values and remote gate values,
      # makes the local equal to the remote.
      class FeatureSynchronizer
        extend Forwardable

        def_delegator :@local_gate_values, :boolean, :local_boolean
        def_delegator :@local_gate_values, :actors, :local_actors
        def_delegator :@local_gate_values, :groups, :local_groups
        def_delegator :@local_gate_values, :percentage_of_actors,
                      :local_percentage_of_actors
        def_delegator :@local_gate_values, :percentage_of_time,
                      :local_percentage_of_time

        def_delegator :@remote_gate_values, :boolean, :remote_boolean
        def_delegator :@remote_gate_values, :actors, :remote_actors
        def_delegator :@remote_gate_values, :groups, :remote_groups
        def_delegator :@remote_gate_values, :percentage_of_actors,
                      :remote_percentage_of_actors
        def_delegator :@remote_gate_values, :percentage_of_time,
                      :remote_percentage_of_time

        def initialize(feature, local_gate_values, remote_gate_values)
          @feature = feature
          @local_gate_values = local_gate_values
          @remote_gate_values = remote_gate_values
        end

        def call
          if remote_disabled?
            return if local_disabled?
            @feature.disable
          elsif remote_boolean_enabled?
            return if local_boolean_enabled?
            @feature.enable
          else
            @feature.disable if local_boolean_enabled?
            sync_actors
            sync_groups
            sync_percentage_of_actors
            sync_percentage_of_time
          end
        end

        private

        def sync_actors
          remote_actors_added = remote_actors - local_actors
          remote_actors_added.each do |flipper_id|
            @feature.enable_actor Actor.new(flipper_id)
          end

          remote_actors_removed = local_actors - remote_actors
          remote_actors_removed.each do |flipper_id|
            @feature.disable_actor Actor.new(flipper_id)
          end
        end

        def sync_groups
          remote_groups_added = remote_groups - local_groups
          remote_groups_added.each do |group_name|
            @feature.enable_group group_name
          end

          remote_groups_removed = local_groups - remote_groups
          remote_groups_removed.each do |group_name|
            @feature.disable_group group_name
          end
        end

        def sync_percentage_of_actors
          return if local_percentage_of_actors == remote_percentage_of_actors

          @feature.enable_percentage_of_actors remote_percentage_of_actors
        end

        def sync_percentage_of_time
          return if local_percentage_of_time == remote_percentage_of_time

          @feature.enable_percentage_of_time remote_percentage_of_time
        end

        def default_config
          @default_config ||= @feature.adapter.default_config
        end

        def default_gate_values
          @default_gate_values ||= GateValues.new(default_config)
        end

        def default_gate_values?(gate_values)
          gate_values == default_gate_values
        end

        def local_disabled?
          default_gate_values? @local_gate_values
        end

        def remote_disabled?
          default_gate_values? @remote_gate_values
        end

        def local_boolean_enabled?
          local_boolean
        end

        def remote_boolean_enabled?
          remote_boolean
        end
      end
    end
  end
end
