# frozen_string_literal: true

require_relative '../identity'

module Datadog
  module Kit
    module AppSec
      # Tracking events
      module Events
        LOGIN_SUCCESS_EVENT = 'users.login.success'
        LOGIN_FAILURE_EVENT = 'users.login.failure'
        SIGNUP_EVENT = 'users.signup'

        class << self
          # Attach login success event information to the trace
          #
          # This method is experimental and may change in the future.
          #
          # @param trace [TraceOperation] Trace to attach data to. Defaults to
          #   active trace.
          # @param span [SpanOperation] Span to attach data to. Defaults to
          #   active span on trace. Note that this should be a service entry span.
          #   When AppSec is enabled, the expected span and trace are automatically
          #   used as defaults.
          # @param user [Hash<Symbol, String>] User information to pass to
          #   Datadog::Kit::Identity.set_user. Must contain at least :id as key.
          # @param others [Hash<String || Symbol, String>] Additional free-form
          #   event information to attach to the trace.
          def track_login_success(trace = nil, span = nil, user:, **others)
            set_trace_and_span_context('track_login_success', trace, span) do |active_trace, active_span|
              user_options = user.dup
              user_id = user_options.delete(:id)

              raise ArgumentError, 'missing required key: :user => { :id }' if user_id.nil?

              track(LOGIN_SUCCESS_EVENT, active_trace, active_span, **others)

              Kit::Identity.set_user(active_trace, active_span, id: user_id, **user_options)
            end
          end

          # Attach login failure event information to the trace
          #
          # This method is experimental and may change in the future.
          #
          # @param trace [TraceOperation] Trace to attach data to. Defaults to
          #   active trace.
          # @param span [SpanOperation] Span to attach data to. Defaults to
          #   active span on trace. Note that this should be a service entry span.
          #   When AppSec is enabled, the expected span and trace are automatically
          #   used as defaults.
          # @param user_id [String] User id that attempted login
          # @param user_exists [bool] Whether the user id that did a login attempt exists.
          # @param others [Hash<String || Symbol, String>] Additional free-form
          #   event information to attach to the trace.
          def track_login_failure(trace = nil, span = nil, user_id:, user_exists:, **others)
            set_trace_and_span_context('track_login_failure', trace, span) do |active_trace, active_span|
              raise ArgumentError, 'user_id cannot be nil' if user_id.nil?

              track(LOGIN_FAILURE_EVENT, active_trace, active_span, **others)

              active_span.set_tag('appsec.events.users.login.failure.usr.id', user_id)
              active_span.set_tag('appsec.events.users.login.failure.usr.exists', user_exists)
            end
          end

          # Attach signup event information to the trace
          #
          # This method is experimental and may change in the future.
          #
          # @param trace [TraceOperation] Trace to attach data to. Defaults to
          #   active trace.
          # @param span [SpanOperation] Span to attach data to. Defaults to
          #   active span on trace. Note that this should be a service entry span.
          #   When AppSec is enabled, the expected span and trace are automatically
          #   used as defaults.
          # @param user [Hash<Symbol, String>] User information to pass to
          #   Datadog::Kit::Identity.set_user. Must contain at least :id as key.
          # @param others [Hash<String || Symbol, String>] Additional free-form
          #   event information to attach to the trace.
          def track_signup(trace = nil, span = nil, user:, **others)
            set_trace_and_span_context('track_signup', trace, span) do |active_trace, active_span|
              user_options = user.dup
              user_id = user_options.delete(:id)

              raise ArgumentError, 'missing required key: :user => { :id }' if user_id.nil?

              track(SIGNUP_EVENT, active_trace, active_span, **others)

              Kit::Identity.set_user(trace, id: user_id, **user_options)
            end
          end

          # Attach custom event information to the trace
          #
          # This method is experimental and may change in the future.
          #
          # @param event [String] Mandatory. Event code.
          # @param trace [TraceOperation] Trace to attach data to. Defaults to
          #   active trace.
          # @param span [SpanOperation] Span to attach data to. Defaults to
          #   active span on trace. Note that this should be a service entry span.
          #   When AppSec is enabled, the expected span and trace are automatically
          #   used as defaults.
          # @param others [Hash<Symbol, String>] Additional free-form
          #   event information to attach to the trace. Key must not
          #   be :track.
          def track(event, trace = nil, span = nil, **others)
            if trace && span
              check_trace_span_integrity(trace, span)

              span.set_tag("appsec.events.#{event}.track", 'true')
              span.set_tag("_dd.appsec.events.#{event}.sdk", 'true')

              others.each do |k, v|
                raise ArgumentError, 'key cannot be :track' if k.to_sym == :track

                span.set_tag("appsec.events.#{event}.#{k}", v) unless v.nil?
              end

              trace.keep!
            else
              set_trace_and_span_context('track', trace, span) do |active_trace, active_span|
                active_span.set_tag("appsec.events.#{event}.track", 'true')
                active_span.set_tag("_dd.appsec.events.#{event}.sdk", 'true')

                others.each do |k, v|
                  raise ArgumentError, 'key cannot be :track' if k.to_sym == :track

                  active_span.set_tag("appsec.events.#{event}.#{k}", v) unless v.nil?
                end

                active_trace.keep!
              end
            end
          end

          private

          def set_trace_and_span_context(method, trace = nil, span = nil)
            if (appsec_scope = Datadog::AppSec.active_scope)
              trace = appsec_scope.trace
              span = appsec_scope.service_entry_span
            end

            trace ||= Datadog::Tracing.active_trace
            span ||=  trace && trace.active_span || Datadog::Tracing.active_span

            unless trace && span
              Datadog.logger.debug(
                "Tracing not enabled. Method ##{method} is a no-op. Please enable tracing if you want ##{method}"\
                ' to track this events'
              )
              return
            end

            check_trace_span_integrity(trace, span)

            yield(trace, span)
          end

          def check_trace_span_integrity(trace, span)
            raise ArgumentError, "span #{span.span_id} does not belong to trace #{trace.id}" if trace.id != span.trace_id
          end
        end
      end
    end
  end
end
