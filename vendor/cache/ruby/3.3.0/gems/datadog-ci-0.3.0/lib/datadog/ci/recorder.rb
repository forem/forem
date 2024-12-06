# frozen_string_literal: true

require "datadog/tracing"
require "datadog/tracing/contrib/analytics"

require_relative "ext/app_types"
require_relative "ext/test"
require_relative "ext/environment"

require "rbconfig"

module Datadog
  module CI
    # Common behavior for CI tests
    module Recorder
      # Creates a new span for a CI test
      def self.trace(span_name, options = {})
        span_options = {
          span_type: Ext::AppTypes::TYPE_TEST
        }.merge(options[:span_options] || {})

        if block_given?
          ::Datadog::Tracing.trace(span_name, **span_options) do |span, trace|
            set_tags!(trace, span, options)
            yield(span, trace)
          end
        else
          span = ::Datadog::Tracing.trace(span_name, **span_options)
          trace = ::Datadog::Tracing.active_trace
          set_tags!(trace, span, options)
          span
        end
      end

      # Adds tags to a CI test span.
      def self.set_tags!(trace, span, tags = {})
        tags ||= {}

        # Set default tags
        trace.origin = Ext::Test::CONTEXT_ORIGIN if trace
        ::Datadog::Tracing::Contrib::Analytics.set_measured(span)
        span.set_tag(Ext::Test::TAG_SPAN_KIND, Ext::AppTypes::TYPE_TEST)

        # Set environment tags
        @environment_tags ||= Ext::Environment.tags(ENV)
        @environment_tags.each { |k, v| span.set_tag(k, v) }

        # Set contextual tags
        span.set_tag(Ext::Test::TAG_FRAMEWORK, tags[:framework]) if tags[:framework]
        span.set_tag(Ext::Test::TAG_FRAMEWORK_VERSION, tags[:framework_version]) if tags[:framework_version]
        span.set_tag(Ext::Test::TAG_NAME, tags[:test_name]) if tags[:test_name]
        span.set_tag(Ext::Test::TAG_SUITE, tags[:test_suite]) if tags[:test_suite]
        span.set_tag(Ext::Test::TAG_TYPE, tags[:test_type]) if tags[:test_type]

        set_environment_runtime_tags!(span)

        span
      end

      def self.passed!(span)
        span.set_tag(Ext::Test::TAG_STATUS, Ext::Test::Status::PASS)
      end

      def self.failed!(span, exception = nil)
        span.status = 1
        span.set_tag(Ext::Test::TAG_STATUS, Ext::Test::Status::FAIL)
        span.set_error(exception) unless exception.nil?
      end

      def self.skipped!(span, exception = nil)
        span.set_tag(Ext::Test::TAG_STATUS, Ext::Test::Status::SKIP)
        span.set_error(exception) unless exception.nil?
      end

      private_class_method def self.set_environment_runtime_tags!(span)
        span.set_tag(Ext::Test::TAG_OS_ARCHITECTURE, ::RbConfig::CONFIG["host_cpu"])
        span.set_tag(Ext::Test::TAG_OS_PLATFORM, ::RbConfig::CONFIG["host_os"])
        span.set_tag(Ext::Test::TAG_RUNTIME_NAME, Core::Environment::Ext::LANG_ENGINE)
        span.set_tag(Ext::Test::TAG_RUNTIME_VERSION, Core::Environment::Ext::ENGINE_VERSION)
      end
    end
  end
end
