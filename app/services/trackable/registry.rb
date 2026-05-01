module Trackable
  # Process-level registry of tracking adapters. Adapter classes are registered
  # at boot via Trackable::Registry.register(:name, AdapterClass). The active
  # set is parsed from the comma-separated TRACKABLE_ADAPTERS ENV var.
  #
  # Adapter instances are memoized per-process so background gems (like
  # analytics-ruby) can accumulate batches across Sidekiq jobs.
  module Registry
    class << self
      def register(name, adapter_class)
        adapters[name.to_sym] = adapter_class
      end

      def lookup(name)
        adapters[name.to_sym]
      end

      def instance_for(name)
        klass = lookup(name)
        return unless klass

        instances[name.to_sym] ||= klass.new
      end

      def active
        active_names.map { |name| instance_for(name) }
      end

      def active_names
        configured_adapter_names.select { |name| instance_for(name)&.enabled? }
      end

      def reset!
        @adapters = {}
        @instances = {}
      end

      private

      def adapters
        @adapters ||= {}
      end

      def instances
        @instances ||= {}
      end

      def configured_adapter_names
        ApplicationConfig["TRACKABLE_ADAPTERS"].to_s.split(",").map { |n| n.strip.to_sym }.reject(&:empty?)
      end
    end
  end
end
