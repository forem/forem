# frozen_string_literal: true

require 'etc'

require_relative '../configuration/agent_settings_resolver'
require_relative '../environment/ext'
require_relative '../environment/platform'
require_relative '../utils/hash'
require_relative 'v1/application'
require_relative 'v1/dependency'
require_relative 'v1/host'
require_relative 'v1/integration'
require_relative 'v1/product'
require_relative '../transport/ext'

module Datadog
  module Core
    module Telemetry
      # Module defining methods for collecting metadata for telemetry
      module Collector
        include Datadog::Core::Configuration
        using Core::Utils::Hash::Refinement

        # Forms a hash of configuration key value pairs to be sent in the additional payload
        def additional_payload
          additional_payload_variables
        end

        # Forms a telemetry application object
        def application
          Telemetry::V1::Application.new(
            env: env,
            language_name: Datadog::Core::Environment::Ext::LANG,
            language_version: Datadog::Core::Environment::Ext::LANG_VERSION,
            products: products,
            runtime_name: Datadog::Core::Environment::Ext::RUBY_ENGINE,
            runtime_version: Datadog::Core::Environment::Ext::ENGINE_VERSION,
            service_name: service_name,
            service_version: service_version,
            tracer_version: library_version
          )
        end

        # Forms a hash of standard key value pairs to be sent in the app-started event configuration
        def configurations
          config = Datadog.configuration
          hash = {
            DD_AGENT_HOST: config.agent.host,
            DD_AGENT_TRANSPORT: agent_transport,
            DD_TRACE_SAMPLE_RATE: format_configuration_value(config.tracing.sampling.default_rate),
            DD_TRACE_REMOVE_INTEGRATION_SERVICE_NAMES_ENABLED: config.tracing.contrib.global_default_service_name.enabled
          }
          peer_service_mapping_str = ''
          unless config.tracing.contrib.peer_service_mapping.empty?
            peer_service_mapping = config.tracing.contrib.peer_service_mapping
            peer_service_mapping_str = peer_service_mapping.map { |key, value| "#{key}:#{value}" }.join(',')
          end
          hash[:DD_TRACE_PEER_SERVICE_MAPPING] = peer_service_mapping_str
          hash.compact!
          hash
        end

        # Forms a telemetry app-started dependencies object
        def dependencies
          Gem.loaded_specs.collect do |name, loaded_gem|
            Datadog::Core::Telemetry::V1::Dependency.new(
              # `hash` should be used when `version` is not available
              name: name, version: loaded_gem.version.to_s, hash: nil
            )
          end
        end

        # Forms a telemetry host object
        def host
          Telemetry::V1::Host.new(
            container_id: Core::Environment::Container.container_id,
            hostname: Core::Environment::Platform.hostname,
            kernel_name: Core::Environment::Platform.kernel_name,
            kernel_release: Core::Environment::Platform.kernel_release,
            kernel_version: Core::Environment::Platform.kernel_version
          )
        end

        # Forms a telemetry app-started integrations object
        def integrations
          Datadog.registry.map do |integration|
            is_instrumented = instrumented?(integration)
            is_enabled = is_instrumented && patched?(integration)
            Telemetry::V1::Integration.new(
              name: integration.name.to_s,
              enabled: is_enabled,
              version: integration_version(integration),
              compatible: integration_compatible?(integration),
              error: (patch_error(integration) if is_instrumented && !is_enabled),
              auto_enabled: is_enabled ? integration_auto_instrument?(integration) : nil
            )
          end
        end

        # Returns the runtime ID of the current process
        def runtime_id
          Datadog::Core::Environment::Identity.id
        end

        # Returns the current as a UNIX timestamp in seconds
        def tracer_time
          Time.now.to_i
        end

        private

        TARGET_OPTIONS = [
          'ci.enabled',
          'logger.level',
          'profiling.advanced.code_provenance_enabled',
          'profiling.advanced.endpoint.collection.enabled',
          'profiling.enabled',
          'runtime_metrics.enabled',
          'tracing.analytics.enabled',
          'tracing.distributed_tracing.propagation_inject_style',
          'tracing.distributed_tracing.propagation_extract_style',
          'tracing.enabled',
          'tracing.log_injection',
          'tracing.partial_flush.enabled',
          'tracing.partial_flush.min_spans_threshold',
          'tracing.priority_sampling',
          'tracing.report_hostname',
          'tracing.sampling.default_rate',
          'tracing.sampling.rate_limit'
        ].freeze

        def additional_payload_variables
          # Whitelist of configuration options to send in additional payload object
          configuration = Datadog.configuration
          options = TARGET_OPTIONS.each_with_object({}) do |option, hash|
            split_option = option.split('.')
            hash[option] = format_configuration_value(configuration.dig(*split_option))
          end

          # Add some more custom additional payload values here
          options['tracing.auto_instrument.enabled'] = !defined?(Datadog::AutoInstrument::LOADED).nil?
          options['tracing.writer_options.buffer_size'] =
            format_configuration_value(configuration.tracing.writer_options[:buffer_size])
          options['tracing.writer_options.flush_interval'] =
            format_configuration_value(configuration.tracing.writer_options[:flush_interval])
          options['logger.instance'] = configuration.logger.instance.class.to_s
          options['appsec.enabled'] = configuration.dig('appsec', 'enabled') if configuration.respond_to?('appsec')
          options['tracing.opentelemetry.enabled'] = !defined?(Datadog::OpenTelemetry::LOADED).nil?
          options['tracing.opentracing.enabled'] = !defined?(Datadog::OpenTracer::LOADED).nil?
          options.compact!
          options
        end

        def format_configuration_value(value)
          # TODO: Add float if telemetry starts accepting it
          case value
          when Integer, String, true, false, nil
            value
          else
            value.to_s
          end
        end

        def env
          Datadog.configuration.env
        end

        def service_name
          Datadog.configuration.service
        end

        def service_version
          Datadog.configuration.version
        end

        def library_version
          Core::Environment::Identity.tracer_version
        end

        def products
          Telemetry::V1::Product.new(profiler: profiler, appsec: appsec)
        end

        def profiler
          { version: library_version }
        end

        def appsec
          { version: library_version }
        end

        def agent_transport
          adapter = Core::Configuration::AgentSettingsResolver.call(Datadog.configuration).adapter
          if adapter == Datadog::Core::Transport::Ext::UnixSocket::ADAPTER
            'UDS'
          else
            'TCP'
          end
        end

        def instrumented_integrations
          Datadog.configuration.tracing.instrumented_integrations
        end

        def instrumented?(integration)
          instrumented_integrations.include?(integration.name)
        end

        def patched?(integration)
          !!integration.klass.patcher.patch_successful
        end

        def integration_auto_instrument?(integration)
          integration.klass.auto_instrument?
        end

        def integration_compatible?(integration)
          integration.klass.class.compatible?
        end

        def integration_version(integration)
          integration.klass.class.version ? integration.klass.class.version.to_s : nil
        end

        def patch_error(integration)
          patch_error_result = integration.klass.patcher.patch_error_result
          if patch_error_result.nil? # if no error occurred during patching, but integration is still not instrumented
            desc = "Available?: #{integration.klass.class.available?}"
            desc += ", Loaded? #{integration.klass.class.loaded?}"
            desc += ", Compatible? #{integration.klass.class.compatible?}"
            desc += ", Patchable? #{integration.klass.class.patchable?}"
            desc
          else
            patch_error_result.compact.to_s
          end
        end
      end
    end
  end
end
