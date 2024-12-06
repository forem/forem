require_relative '../../tracing/configuration/ext'
require_relative '../../core/environment/variable_helpers'
require_relative 'http'

module Datadog
  module Tracing
    module Configuration
      # Configuration settings for tracing.
      # @public_api
      # rubocop:disable Metrics/AbcSize
      # rubocop:disable Metrics/BlockLength
      # rubocop:disable Metrics/CyclomaticComplexity
      # rubocop:disable Metrics/MethodLength
      # rubocop:disable Layout/LineLength
      module Settings
        def self.extended(base)
          base.class_eval do
            # Tracer specific configurations.
            # @public_api
            settings :tracing do
              # Legacy [App Analytics](https://docs.datadoghq.com/tracing/legacy_app_analytics/) configuration.
              #
              # @configure_with {Datadog::Tracing}
              # @deprecated Use [Trace Retention and Ingestion](https://docs.datadoghq.com/tracing/trace_retention_and_ingestion/)
              #   controls.
              # @public_api
              settings :analytics do
                # @default `DD_TRACE_ANALYTICS_ENABLED` environment variable, otherwise `nil`
                # @return [Boolean,nil]
                option :enabled do |o|
                  o.type :bool, nilable: true
                  o.env Tracing::Configuration::Ext::Analytics::ENV_TRACE_ANALYTICS_ENABLED
                end
              end

              # [Distributed Tracing](https://docs.datadoghq.com/tracing/setup_overview/setup/ruby/#distributed-tracing) propagation
              # style configuration.
              #
              # The supported formats are:
              # * `Datadog`: Datadog propagation format, described by [Distributed Tracing](https://docs.datadoghq.com/tracing/setup_overview/setup/ruby/#distributed-tracing).
              # * `b3multi`: B3 Propagation using multiple headers, described by [openzipkin/b3-propagation](https://github.com/openzipkin/b3-propagation#multiple-headers).
              # * `b3`: B3 Propagation using a single header, described by [openzipkin/b3-propagation](https://github.com/openzipkin/b3-propagation#single-header).
              #
              # @public_api
              settings :distributed_tracing do
                # An ordered list of what data propagation styles the tracer will use to extract distributed tracing propagation
                # data from incoming requests and messages.
                #
                # The tracer will try to find distributed headers in the order they are present in the list provided to this option.
                # The first format to have valid data present will be used.
                #
                # @default `DD_TRACE_PROPAGATION_STYLE_EXTRACT` environment variable (comma-separated list),
                #   otherwise `['Datadog','b3multi','b3']`.
                # @return [Array<String>]
                option :propagation_extract_style do |o|
                  o.type :array
                  o.deprecated_env Tracing::Configuration::Ext::Distributed::ENV_PROPAGATION_STYLE_EXTRACT_OLD
                  o.env Tracing::Configuration::Ext::Distributed::ENV_PROPAGATION_STYLE_EXTRACT
                  # DEV-2.0: Change default value to `tracecontext, Datadog`.
                  # Look for all headers by default
                  o.default(
                    [
                      Tracing::Configuration::Ext::Distributed::PROPAGATION_STYLE_DATADOG,
                      Tracing::Configuration::Ext::Distributed::PROPAGATION_STYLE_B3_MULTI_HEADER,
                      Tracing::Configuration::Ext::Distributed::PROPAGATION_STYLE_B3_SINGLE_HEADER,
                    ]
                  )
                  o.after_set do |styles|
                    # Modernize B3 options
                    # DEV-2.0: Can be removed with the removal of deprecated B3 constants.
                    styles.map! do |style|
                      case style
                      when Tracing::Configuration::Ext::Distributed::PROPAGATION_STYLE_B3
                        Tracing::Configuration::Ext::Distributed::PROPAGATION_STYLE_B3_MULTI_HEADER
                      when Tracing::Configuration::Ext::Distributed::PROPAGATION_STYLE_B3_SINGLE_HEADER_OLD
                        Tracing::Configuration::Ext::Distributed::PROPAGATION_STYLE_B3_SINGLE_HEADER
                      else
                        style
                      end
                    end
                  end
                end

                # The data propagation styles the tracer will use to inject distributed tracing propagation
                # data into outgoing requests and messages.
                #
                # The tracer will inject data from all styles specified in this option.
                #
                # @default `DD_TRACE_PROPAGATION_STYLE_INJECT` environment variable (comma-separated list), otherwise `['Datadog']`.
                # @return [Array<String>]
                option :propagation_inject_style do |o|
                  o.type :array
                  o.deprecated_env Tracing::Configuration::Ext::Distributed::ENV_PROPAGATION_STYLE_INJECT_OLD
                  o.env Tracing::Configuration::Ext::Distributed::ENV_PROPAGATION_STYLE_INJECT
                  # DEV-2.0: Change default value to `tracecontext, Datadog`.
                  o.default [Tracing::Configuration::Ext::Distributed::PROPAGATION_STYLE_DATADOG]
                  o.after_set do |styles|
                    # Modernize B3 options
                    # DEV-2.0: Can be removed with the removal of deprecated B3 constants.
                    styles.map! do |style|
                      case style
                      when Tracing::Configuration::Ext::Distributed::PROPAGATION_STYLE_B3
                        Tracing::Configuration::Ext::Distributed::PROPAGATION_STYLE_B3_MULTI_HEADER
                      when Tracing::Configuration::Ext::Distributed::PROPAGATION_STYLE_B3_SINGLE_HEADER_OLD
                        Tracing::Configuration::Ext::Distributed::PROPAGATION_STYLE_B3_SINGLE_HEADER
                      else
                        style
                      end
                    end
                  end
                end

                # An ordered list of what data propagation styles the tracer will use to extract distributed tracing propagation
                # data from incoming requests and inject into outgoing requests.
                #
                # This configuration is the equivalent of configuring both {propagation_extract_style}
                # {propagation_inject_style} to value set to {propagation_style}.
                #
                # @default `DD_TRACE_PROPAGATION_STYLE` environment variable (comma-separated list).
                # @return [Array<String>]
                option :propagation_style do |o|
                  o.type :array
                  o.env Configuration::Ext::Distributed::ENV_PROPAGATION_STYLE
                  o.default []
                  o.after_set do |styles|
                    next if styles.empty?

                    # Modernize B3 options
                    # DEV-2.0: Can be removed with the removal of deprecated B3 constants.
                    styles.map! do |style|
                      case style
                      when Tracing::Configuration::Ext::Distributed::PROPAGATION_STYLE_B3
                        Tracing::Configuration::Ext::Distributed::PROPAGATION_STYLE_B3_MULTI_HEADER
                      when Tracing::Configuration::Ext::Distributed::PROPAGATION_STYLE_B3_SINGLE_HEADER_OLD
                        Tracing::Configuration::Ext::Distributed::PROPAGATION_STYLE_B3_SINGLE_HEADER
                      else
                        style
                      end
                    end

                    set_option(:propagation_extract_style, styles)
                    set_option(:propagation_inject_style, styles)
                  end
                end
              end

              # Enable trace collection and span generation.
              #
              # You can use this option to disable tracing without having to
              # remove the library as a whole.
              #
              # @default `DD_TRACE_ENABLED` environment variable, otherwise `true`
              # @return [Boolean]
              option :enabled do |o|
                o.env Tracing::Configuration::Ext::ENV_ENABLED
                o.default true
                o.type :bool
              end

              # Comma-separated, case-insensitive list of header names that are reported in incoming and outgoing HTTP requests.
              #
              # Each header in the list can either be:
              # * A header name, which is mapped to the respective tags `http.request.headers.<header name>` and `http.response.headers.<header name>`.
              # * A key value pair, "header name:tag name", which is mapped to the span tag `tag name`.
              #
              # You can mix the two types of header declaration in the same list.
              # Tag names will be normalized based on the [Datadog tag normalization rules](https://docs.datadoghq.com/getting_started/tagging/#defining-tags).
              #
              # @default `DD_TRACE_HEADER_TAGS` environment variable, otherwise an empty set of tags
              # @return [Array<String>]
              option :header_tags do |o|
                o.env Configuration::Ext::ENV_HEADER_TAGS
                o.type :array
                o.default []
                o.setter { |header_tags, _| Configuration::HTTP::HeaderTags.new(header_tags) }
              end

              # Enable 128 bit trace id generation.
              #
              # @default `DD_TRACE_128_BIT_TRACEID_GENERATION_ENABLED` environment variable, otherwise `false`
              # @return [Boolean]
              option :trace_id_128_bit_generation_enabled do |o|
                o.env Tracing::Configuration::Ext::ENV_TRACE_ID_128_BIT_GENERATION_ENABLED
                o.default false
                o.type :bool
              end

              # Enable 128 bit trace id injected for logging.
              #
              # @default `DD_TRACE_128_BIT_TRACEID_LOGGING_ENABLED` environment variable, otherwise `false`
              # @return [Boolean]
              #
              # It is not supported by our backend yet. Do not enable it.
              option :trace_id_128_bit_logging_enabled do |o|
                o.env Tracing::Configuration::Ext::Correlation::ENV_TRACE_ID_128_BIT_LOGGING_ENABLED
                o.default false
                o.type :bool
              end

              # A custom tracer instance.
              #
              # It must respect the contract of {Datadog::Tracing::Tracer}.
              # It's recommended to delegate methods to {Datadog::Tracing::Tracer} to ease the implementation
              # of a custom tracer.
              #
              # This option will not return the live tracer instance: it only holds a custom tracing instance, if any.
              #
              # For internal use only.
              #
              # @default `nil`
              # @return [Object,nil]
              option :instance

              # Automatic correlation between tracing and logging.
              # @see https://docs.datadoghq.com/tracing/setup_overview/setup/ruby/#trace-correlation
              # @return [Boolean]
              option :log_injection do |o|
                o.env Tracing::Configuration::Ext::Correlation::ENV_LOGS_INJECTION_ENABLED
                o.default true
                o.type :bool
              end

              # Configures an alternative trace transport behavior, where
              # traces can be sent to the agent and backend before all spans
              # have finished.
              #
              # This is useful for long-running jobs or very large traces.
              #
              # The trace flame graph will display the partial trace as it is received and constantly
              # update with new spans as they are flushed.
              # @public_api
              settings :partial_flush do
                # Enable partial trace flushing.
                #
                # @default `false`
                # @return [Boolean]
                option :enabled, default: false, type: :bool

                # Minimum number of finished spans required in a single unfinished trace before
                # the tracer will consider that trace for partial flushing.
                #
                # This option helps preserve a minimum amount of batching in the
                # flushing process, reducing network overhead.
                #
                # This threshold only applies to unfinished traces. Traces that have finished
                # are always flushed immediately.
                #
                # @default 500
                # @return [Integer]
                option :min_spans_threshold, default: 500, type: :int
              end

              # Enables {https://docs.datadoghq.com/tracing/trace_retention_and_ingestion/#datadog-intelligent-retention-filter
              # Datadog intelligent retention filter}.
              # @default `true`
              # @return [Boolean,nil]
              option :priority_sampling

              option :report_hostname do |o|
                o.env Tracing::Configuration::Ext::NET::ENV_REPORT_HOSTNAME
                o.default false
                o.type :bool
              end

              # A custom sampler instance.
              # The object must respect the {Datadog::Tracing::Sampling::Sampler} interface.
              # @default `nil`
              # @return [Object,nil]
              option :sampler

              # Client-side sampling configuration.
              # @see https://docs.datadoghq.com/tracing/trace_ingestion/mechanisms/
              # @public_api
              settings :sampling do
                # Default sampling rate for the tracer.
                #
                # If `nil`, the trace uses an automatic sampling strategy that tries to ensure
                # the collection of traces that are considered important (e.g. traces with an error, traces
                # for resources not seen recently).
                #
                # @default `DD_TRACE_SAMPLE_RATE` environment variable, otherwise `nil`.
                # @return [Float, nil]
                option :default_rate do |o|
                  o.type :float, nilable: true
                  o.env Tracing::Configuration::Ext::Sampling::ENV_SAMPLE_RATE
                end

                # Rate limit for number of spans per second.
                #
                # Spans created above the limit will contribute to service metrics, but won't
                # have their payload stored.
                #
                # @default `DD_TRACE_RATE_LIMIT` environment variable, otherwise 100.
                # @return [Numeric,nil]
                option :rate_limit do |o|
                  o.type :int, nilable: true
                  o.env Tracing::Configuration::Ext::Sampling::ENV_RATE_LIMIT
                  o.default 100
                end

                # Trace sampling rules.
                # These rules control whether a trace is kept or dropped by the tracer.
                #
                # The `rules` format is a String with a JSON array of objects:
                # Each object must have a `sample_rate`, and the `name` and `service` fields
                # are optional. The `sample_rate` value must be between 0.0 and 1.0 (inclusive).
                # `name` and `service` are Strings that allow the `sample_rate` to be applied only
                # to traces matching the `name` and `service`.
                #
                # @default `DD_TRACE_SAMPLING_RULES` environment variable. Otherwise `nil`.
                # @return [String,nil]
                # @public_api
                option :rules do |o|
                  o.default { ENV.fetch(Configuration::Ext::Sampling::ENV_RULES, nil) }
                end

                # Single span sampling rules.
                # These rules allow a span to be kept when its encompassing trace is dropped.
                #
                # The syntax for single span sampling rules can be found here:
                # TODO: <Single Span Sampling documentation URL here>
                #
                # @default `DD_SPAN_SAMPLING_RULES` environment variable.
                #   Otherwise, `ENV_SPAN_SAMPLING_RULES_FILE` environment variable.
                #   Otherwise `nil`.
                # @return [String,nil]
                # @public_api
                option :span_rules do |o|
                  o.type :string, nilable: true
                  o.default do
                    rules = ENV[Tracing::Configuration::Ext::Sampling::Span::ENV_SPAN_SAMPLING_RULES]
                    rules_file = ENV[Tracing::Configuration::Ext::Sampling::Span::ENV_SPAN_SAMPLING_RULES_FILE]

                    if rules
                      if rules_file
                        Datadog.logger.warn(
                          'Both DD_SPAN_SAMPLING_RULES and DD_SPAN_SAMPLING_RULES_FILE were provided: only ' \
                            'DD_SPAN_SAMPLING_RULES will be used. Please do not provide DD_SPAN_SAMPLING_RULES_FILE when ' \
                            'also providing DD_SPAN_SAMPLING_RULES as their configuration conflicts. ' \
                            "DD_SPAN_SAMPLING_RULES_FILE=#{rules_file} DD_SPAN_SAMPLING_RULES=#{rules}"
                        )
                      end
                      rules
                    elsif rules_file
                      begin
                        File.read(rules_file)
                      rescue => e
                        # `File#read` errors have clear and actionable messages, no need to add extra exception info.
                        Datadog.logger.warn(
                          "Cannot read span sampling rules file `#{rules_file}`: #{e.message}." \
                          'No span sampling rules will be applied.'
                        )
                        nil
                      end
                    end
                  end
                end
              end

              # [Continuous Integration Visibility](https://docs.datadoghq.com/continuous_integration/) configuration.
              # @public_api
              settings :test_mode do
                # Enable test mode. This allows the tracer to collect spans from test runs.
                #
                # It also prevents the tracer from collecting spans in a production environment. Only use in a test environment.
                #
                # @default `DD_TRACE_TEST_MODE_ENABLED` environment variable, otherwise `false`
                # @return [Boolean]
                option :enabled do |o|
                  o.type :bool
                  o.default false
                  o.env Tracing::Configuration::Ext::Test::ENV_MODE_ENABLED
                end

                # Use async writer in test mode
                option :async do |o|
                  o.type :bool
                  o.default false
                end

                option :trace_flush

                option :writer_options do |o|
                  o.type :hash
                  o.default({})
                end
              end

              # @see file:docs/GettingStarted.md#configuring-the-transport-layer Configuring the transport layer
              #
              # A {Proc} that configures a custom tracer transport.
              # @yield Receives a {Datadog::Tracing::Transport::HTTP} that can be modified with custom adapters and settings.
              # @yieldparam [Datadog::Tracing::Transport::HTTP] t transport to be configured.
              # @default `nil`
              # @return [Proc,nil]
              option :transport_options do |o|
                o.type :proc, nilable: true
                o.default nil
              end
              # A custom writer instance.
              # The object must respect the {Datadog::Tracing::Writer} interface.
              #
              # This option is recommended for internal use only.
              #
              # @default `nil`
              # @return [Object,nil]
              option :writer

              # A custom {Hash} with keyword options to be passed to {Datadog::Tracing::Writer#initialize}.
              #
              # This option is recommended for internal use only.
              #
              # @default `{}`
              # @return [Hash]
              option :writer_options do |o|
                o.type :hash
                o.default({})
              end

              # Client IP configuration
              # @public_api
              settings :client_ip do
                # Whether client IP collection is enabled. When enabled client IPs from HTTP requests will
                #   be reported in traces.
                #
                # Usage of the DD_TRACE_CLIENT_IP_HEADER_DISABLED environment variable is deprecated.
                #
                # @see https://docs.datadoghq.com/tracing/configure_data_security#configuring-a-client-ip-header
                #
                # @default `DD_TRACE_CLIENT_IP_ENABLED` environment variable, otherwise `false`.
                # @return [Boolean]
                option :enabled do |o|
                  o.type :bool
                  o.default do
                    disabled = Core::Environment::VariableHelpers.env_to_bool(Tracing::Configuration::Ext::ClientIp::ENV_DISABLED)

                    enabled = if disabled.nil?
                                false
                              else
                                Datadog::Core.log_deprecation do
                                  "#{Tracing::Configuration::Ext::ClientIp::ENV_DISABLED} environment variable is deprecated, use #{Tracing::Configuration::Ext::ClientIp::ENV_ENABLED} instead."
                                end

                                !disabled
                              end

                    # ENABLED env var takes precedence over deprecated DISABLED
                    Core::Environment::VariableHelpers.env_to_bool(Tracing::Configuration::Ext::ClientIp::ENV_ENABLED, enabled)
                  end
                end

                # An optional name of a custom header to resolve the client IP from.
                #
                # @default `DD_TRACE_CLIENT_IP_HEADER` environment variable, otherwise `nil`.
                # @return [String,nil]
                option :header_name do |o|
                  o.type :string, nilable: true
                  o.env Tracing::Configuration::Ext::ClientIp::ENV_HEADER_NAME
                end
              end

              # Maximum size for the `x-datadog-tags` distributed trace tags header.
              #
              # If the serialized size of distributed trace tags is larger than this value, it will
              # not be parsed if incoming, nor exported if outgoing. An error message will be logged
              # in this case.
              #
              # @default `DD_TRACE_X_DATADOG_TAGS_MAX_LENGTH` environment variable, otherwise `512`
              # @return [Integer]
              option :x_datadog_tags_max_length do |o|
                o.type :int
                o.env Tracing::Configuration::Ext::Distributed::ENV_X_DATADOG_TAGS_MAX_LENGTH
                o.default 512
              end
            end
          end
        end
      end
      # rubocop:enable Metrics/AbcSize
      # rubocop:enable Metrics/BlockLength
      # rubocop:enable Metrics/CyclomaticComplexity
      # rubocop:enable Metrics/MethodLength
      # rubocop:enable Layout/LineLength
    end
  end
end
