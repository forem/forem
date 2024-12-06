module Flipper
  module Adapters
    class DualWrite
      include ::Flipper::Adapter

      # Public: The name of the adapter.
      attr_reader :name

      # Public: Build a new sync instance.
      #
      # local - The local flipper adapter that should serve reads.
      # remote - The remote flipper adapter that writes should go to first (in
      #          addition to the local adapter).
      def initialize(local, remote, options = {})
        @name = :dual_write
        @local = local
        @remote = remote
      end

      def features
        @local.features
      end

      def get(feature)
        @local.get(feature)
      end

      def get_multi(features)
        @local.get_multi(features)
      end

      def get_all
        @local.get_all
      end

      def add(feature)
        @remote.add(feature).tap { @local.add(feature) }
      end

      def remove(feature)
        @remote.remove(feature).tap { @local.remove(feature) }
      end

      def clear(feature)
        @remote.clear(feature).tap { @local.clear(feature) }
      end

      def enable(feature, gate, thing)
        @remote.enable(feature, gate, thing).tap do
          @local.enable(feature, gate, thing)
        end
      end

      def disable(feature, gate, thing)
        @remote.disable(feature, gate, thing).tap do
          @local.disable(feature, gate, thing)
        end
      end
    end
  end
end
