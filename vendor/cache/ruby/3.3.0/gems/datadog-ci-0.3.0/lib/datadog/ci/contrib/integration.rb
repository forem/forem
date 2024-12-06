# frozen_string_literal: true

require_relative "settings"

module Datadog
  module CI
    module Contrib
      module Integration
        @registry = {}

        def self.included(base)
          base.extend(ClassMethods)
          base.include(InstanceMethods)
        end

        def self.register(klass, name)
          registry[name] = klass.new
        end

        def self.registry
          @registry
        end

        # Class-level methods for Integration
        module ClassMethods
          def register_as(name)
            Integration.register(self, name)
          end

          # Version of the integration target code in the environment.
          #
          # This is the gem version, when the instrumentation target is a Ruby gem.
          #
          # If the target for instrumentation has concept of versioning, override {.version},
          # otherwise override {.available?} and implement a custom target presence check.
          # @return [Object] the target version
          def version
            nil
          end

          # Is the target available to be instrumented? (e.g. gem installed?)
          #
          # The target doesn't have to be loaded (e.g. `require`) yet, but needs to be able
          # to be loaded before instrumentation can commence.
          #
          # By default, {.available?} checks if {.version} returned a non-nil object.
          #
          # If the target for instrumentation has concept of versioning, override {.version},
          # otherwise override {.available?} and implement a custom target presence check.
          # @return [Boolean] is the target available for instrumentation in this Ruby environment?
          def available?
            !version.nil?
          end

          # Is the target loaded into the application? (e.g. gem required? Constant defined?)
          #
          # The target's objects should be ready to be referenced by the instrumented when {.loaded}
          # returns `true`.
          #
          # @return [Boolean] is the target ready to be referenced during instrumentation?
          def loaded?
            true
          end

          # Is this instrumentation compatible with the available target? (e.g. minimum version met?)
          # @return [Boolean] is the available target compatible with this instrumentation?
          def compatible?
            available?
          end

          # Can the patch for this integration be applied?
          #
          # By default, this is equivalent to {#available?}, {#loaded?}, and {#compatible?}
          # all being truthy.
          def patchable?
            available? && loaded? && compatible?
          end
        end

        module InstanceMethods
          # returns the configuration instance.
          def configuration
            @configuration ||= new_configuration
          end

          def configure(options = {}, &block)
            configuration.configure(options, &block)
            configuration
          end

          # Resets all configuration options
          def reset_configuration!
            @configuration = nil
          end

          def enabled
            configuration.enabled
          end

          # The patcher module to inject instrumented objects into the instrumentation target.
          #
          # {Contrib::Patcher} includes the basic functionality of a patcher. `include`ing
          # {Contrib::Patcher} into a new module is the recommend way to create a custom patcher.
          #
          # @return [Contrib::Patcher] a module that `include`s {Contrib::Patcher}
          def patcher
            nil
          end

          # @!visibility private
          def patch
            # @type var patcher_klass: untyped
            patcher_klass = patcher
            if !self.class.patchable? || patcher_klass.nil?
              return {
                available: self.class.available?,
                loaded: self.class.loaded?,
                compatible: self.class.compatible?,
                patchable: self.class.patchable?
              }
            end

            patcher_klass.patch
            true
          end

          # Can the patch for this integration be applied automatically?
          # @return [Boolean] can the tracer activate this instrumentation without explicit user input?
          def auto_instrument?
            true
          end

          protected

          # Returns a new configuration object for this integration.
          #
          # This method normally needs to be overridden for each integration
          # as their settings, defaults and environment variables are
          # specific for each integration.
          #
          # @return [Datadog::CI::Contrib::Settings] a new, integration-specific settings object
          def new_configuration
            Datadog::CI::Contrib::Settings.new
          end
        end
      end
    end
  end
end
