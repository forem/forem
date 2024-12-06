# frozen_string_literal: true

require_relative "../ext/settings"

module Datadog
  module CI
    module Configuration
      # Adds CI behavior to ddtrace settings
      module Settings
        InvalidIntegrationError = Class.new(StandardError)

        def self.extended(base)
          base = base.singleton_class unless base.is_a?(Class)
          add_settings!(base)
        end

        def self.add_settings!(base)
          base.class_eval do
            settings :ci do
              option :enabled do |o|
                o.type :bool
                o.env CI::Ext::Settings::ENV_MODE_ENABLED
                o.default false
              end

              option :agentless_mode_enabled do |o|
                o.type :bool
                o.env CI::Ext::Settings::ENV_AGENTLESS_MODE_ENABLED
                o.default false
              end

              option :agentless_url do |o|
                o.type :string, nilable: true
                o.env CI::Ext::Settings::ENV_AGENTLESS_URL
              end

              define_method(:instrument) do |integration_name, options = {}, &block|
                return unless enabled

                integration = fetch_integration(integration_name)
                integration.configure(options, &block)

                return unless integration.enabled

                patch_results = integration.patch
                next if patch_results == true

                error_message = <<-ERROR
                  Available?: #{patch_results[:available]}, Loaded?: #{patch_results[:loaded]},
                  Compatible?: #{patch_results[:compatible]}, Patchable?: #{patch_results[:patchable]}"
                ERROR
                Datadog.logger.warn("Unable to patch #{integration_name} (#{error_message})")
              end

              define_method(:[]) do |integration_name|
                fetch_integration(integration_name).configuration
              end

              # TODO: Deprecate in the next major version, as `instrument` better describes this method's purpose
              alias_method :use, :instrument

              option :trace_flush

              option :writer_options do |o|
                o.type :hash
                o.default({})
              end

              define_method(:fetch_integration) do |name|
                Datadog::CI::Contrib::Integration.registry[name] ||
                  raise(InvalidIntegrationError, "'#{name}' is not a valid integration.")
              end
            end
          end
        end
      end
    end
  end
end
