require 'json'

require_relative 'gateway/request'
require_relative 'gateway/response'
require_relative '../../instrumentation/gateway'
require_relative '../../processor'
require_relative '../../response'

require_relative '../../../tracing/client_ip'
require_relative '../../../tracing/contrib/rack/header_collection'

module Datadog
  module AppSec
    module Contrib
      module Rack
        # Topmost Rack middleware for AppSec
        # This should be inserted just below Datadog::Tracing::Contrib::Rack::TraceMiddleware
        class RequestMiddleware
          def initialize(app, opt = {})
            @app = app

            @oneshot_tags_sent = false
          end

          # rubocop:disable Metrics/AbcSize,Metrics/PerceivedComplexity,Metrics/CyclomaticComplexity,Metrics/MethodLength
          def call(env)
            return @app.call(env) unless Datadog::AppSec.enabled?

            Datadog::Core::Remote.active_remote.barrier(:once) unless Datadog::Core::Remote.active_remote.nil?

            processor = nil
            ready = false
            scope = nil

            # For a given request, keep using the first Rack stack scope for
            # nested apps. Don't set `context` local variable so that on popping
            # out of this nested stack we don't finalize the parent's context
            return @app.call(env) if active_scope(env)

            Datadog::AppSec.reconfigure_lock do
              processor = Datadog::AppSec.processor

              if !processor.nil? && processor.ready?
                scope = Datadog::AppSec::Scope.activate_scope(active_trace, active_span, processor)
                env[Datadog::AppSec::Ext::SCOPE_KEY] = scope
                ready = true
              end
            end

            # TODO: handle exceptions, except for @app.call

            return @app.call(env) unless ready

            gateway_request = Gateway::Request.new(env)

            add_appsec_tags(processor, scope, env)

            request_return, request_response = catch(::Datadog::AppSec::Ext::INTERRUPT) do
              Instrumentation.gateway.push('rack.request', gateway_request) do
                @app.call(env)
              end
            end

            if request_response
              blocked_event = request_response.find { |action, _options| action == :block }
              request_return = AppSec::Response.negotiate(env, blocked_event.last[:actions]).to_rack if blocked_event
            end

            gateway_response = Gateway::Response.new(
              request_return[2],
              request_return[0],
              request_return[1],
              scope: scope,
            )

            _response_return, response_response = Instrumentation.gateway.push('rack.response', gateway_response)

            result = scope.processor_context.extract_schema

            if result
              scope.processor_context.events << {
                trace: scope.trace,
                span: scope.service_entry_span,
                waf_result: result,
              }
            end

            scope.processor_context.events.each do |e|
              e[:response] ||= gateway_response
              e[:request]  ||= gateway_request
            end

            AppSec::Event.record(scope.service_entry_span, *scope.processor_context.events)

            if response_response
              blocked_event = response_response.find { |action, _options| action == :block }
              request_return = AppSec::Response.negotiate(env, blocked_event.last[:actions]).to_rack if blocked_event
            end

            request_return
          ensure
            if scope
              add_waf_runtime_tags(scope)
              Datadog::AppSec::Scope.deactivate_scope
            end
          end
          # rubocop:enable Metrics/AbcSize,Metrics/PerceivedComplexity,Metrics/CyclomaticComplexity,Metrics/MethodLength

          private

          def active_scope(env)
            env[Datadog::AppSec::Ext::SCOPE_KEY]
          end

          def active_trace
            # TODO: factor out tracing availability detection

            return unless defined?(Datadog::Tracing)

            Datadog::Tracing.active_trace
          end

          def active_span
            # TODO: factor out tracing availability detection

            return unless defined?(Datadog::Tracing)

            Datadog::Tracing.active_span
          end

          def add_appsec_tags(processor, scope, env)
            span = scope.service_entry_span
            trace = scope.trace

            return unless trace && span

            span.set_tag('_dd.appsec.enabled', 1)
            span.set_tag('_dd.runtime_family', 'ruby')
            span.set_tag('_dd.appsec.waf.version', Datadog::AppSec::WAF::VERSION::BASE_STRING)

            if span && span.get_tag(Tracing::Metadata::Ext::HTTP::TAG_CLIENT_IP).nil?
              request_header_collection = Datadog::Tracing::Contrib::Rack::Header::RequestHeaderCollection.new(env)

              # always collect client ip, as this is part of AppSec provided functionality
              Datadog::Tracing::ClientIp.set_client_ip_tag!(
                span,
                headers: request_header_collection,
                remote_ip: env['REMOTE_ADDR']
              )
            end

            if processor.diagnostics
              diagnostics = processor.diagnostics

              span.set_tag('_dd.appsec.event_rules.version', diagnostics['ruleset_version'])

              unless @oneshot_tags_sent
                # Small race condition, but it's inoccuous: worst case the tags
                # are sent a couple of times more than expected
                @oneshot_tags_sent = true

                span.set_tag('_dd.appsec.event_rules.loaded', diagnostics['rules']['loaded'].size.to_f)
                span.set_tag('_dd.appsec.event_rules.error_count', diagnostics['rules']['failed'].size.to_f)
                span.set_tag('_dd.appsec.event_rules.errors', JSON.dump(diagnostics['rules']['errors']))
                span.set_tag('_dd.appsec.event_rules.addresses', JSON.dump(processor.addresses))

                # Ensure these tags reach the backend
                trace.keep!
                trace.set_tag(
                  Datadog::Tracing::Metadata::Ext::Distributed::TAG_DECISION_MAKER,
                  Datadog::Tracing::Sampling::Ext::Decision::ASM
                )
              end
            end
          end

          def add_waf_runtime_tags(scope)
            span = scope.service_entry_span
            context = scope.processor_context

            return unless span && context

            span.set_tag('_dd.appsec.waf.timeouts', context.timeouts)

            # these tags expect time in us
            span.set_tag('_dd.appsec.waf.duration', context.time_ns / 1000.0)
            span.set_tag('_dd.appsec.waf.duration_ext', context.time_ext_ns / 1000.0)
          end
        end
      end
    end
  end
end
