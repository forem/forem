require "flipper/feature"
require "flipper/gate_values"
require "flipper/adapters/sync/feature_synchronizer"

module Flipper
  module Adapters
    class Sync
      # Public: Given a local and remote adapter, it can update the local to
      # match the remote doing only the necessary enable/disable operations.
      class Synchronizer
        # Public: Initializes a new synchronizer.
        #
        # local - The Flipper adapter to get in sync with the remote.
        # remote - The Flipper adapter that is source of truth that the local
        #          adapter should be brought in line with.
        # options - The Hash of options.
        #           :instrumenter - The instrumenter used to instrument.
        #           :raise - Should errors be raised (default: true).
        def initialize(local, remote, options = {})
          @local = local
          @remote = remote
          @instrumenter = options.fetch(:instrumenter, Instrumenters::Noop)
          @raise = options.fetch(:raise, true)
        end

        # Public: Forces a sync.
        def call
          @instrumenter.instrument("synchronizer_call.flipper") { sync }
        end

        private

        def sync
          local_get_all = @local.get_all
          remote_get_all = @remote.get_all

          # Sync all the gate values.
          remote_get_all.each do |feature_key, remote_gates_hash|
            feature = Feature.new(feature_key, @local)
            # Check if feature_key is in hash before accessing to prevent unintended hash modification
            local_gates_hash = local_get_all.key?(feature_key) ? local_get_all[feature_key] : @local.default_config
            local_gate_values = GateValues.new(local_gates_hash)
            remote_gate_values = GateValues.new(remote_gates_hash)
            FeatureSynchronizer.new(feature, local_gate_values, remote_gate_values).call
          end

          # Add features that are missing in local and present in remote.
          features_to_add = remote_get_all.keys - local_get_all.keys
          features_to_add.each { |key| Feature.new(key, @local).add }

          # Remove features that are present in local and missing in remote.
          features_to_remove = local_get_all.keys - remote_get_all.keys
          features_to_remove.each { |key| Feature.new(key, @local).remove }

          nil
        rescue => exception
          @instrumenter.instrument("synchronizer_exception.flipper", exception: exception)
          raise if @raise
        end
      end
    end
  end
end
