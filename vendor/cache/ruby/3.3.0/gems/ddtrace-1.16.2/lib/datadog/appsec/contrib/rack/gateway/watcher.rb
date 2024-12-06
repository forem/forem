require_relative '../../../instrumentation/gateway'
require_relative '../../../reactive/operation'
require_relative '../reactive/request'
require_relative '../reactive/request_body'
require_relative '../reactive/response'
require_relative '../../../event'

module Datadog
  module AppSec
    module Contrib
      module Rack
        module Gateway
          # Watcher for Rack gateway events
          module Watcher
            class << self
              def watch
                gateway = Instrumentation.gateway

                watch_request(gateway)
                watch_response(gateway)
                watch_request_body(gateway)
              end

              def watch_request(gateway = Instrumentation.gateway)
                gateway.watch('rack.request', :appsec) do |stack, gateway_request|
                  block = false
                  event = nil
                  scope = gateway_request.env[Datadog::AppSec::Ext::SCOPE_KEY]

                  AppSec::Reactive::Operation.new('rack.request') do |op|
                    Rack::Reactive::Request.subscribe(op, scope.processor_context) do |result|
                      if result.status == :match
                        # TODO: should this hash be an Event instance instead?
                        event = {
                          waf_result: result,
                          trace: scope.trace,
                          span: scope.service_entry_span,
                          request: gateway_request,
                          actions: result.actions
                        }

                        if scope.service_entry_span
                          scope.service_entry_span.set_tag('appsec.blocked', 'true') if result.actions.include?('block')
                          scope.service_entry_span.set_tag('appsec.event', 'true')
                        end

                        scope.processor_context.events << event
                      end
                    end

                    block = Rack::Reactive::Request.publish(op, gateway_request)
                  end

                  next [nil, [[:block, event]]] if block

                  ret, res = stack.call(gateway_request.request)

                  if event
                    res ||= []
                    res << [:monitor, event]
                  end

                  [ret, res]
                end
              end

              def watch_response(gateway = Instrumentation.gateway)
                gateway.watch('rack.response', :appsec) do |stack, gateway_response|
                  block = false

                  event = nil
                  scope = gateway_response.scope

                  AppSec::Reactive::Operation.new('rack.response') do |op|
                    Rack::Reactive::Response.subscribe(op, scope.processor_context) do |result|
                      if result.status == :match
                        # TODO: should this hash be an Event instance instead?
                        event = {
                          waf_result: result,
                          trace: scope.trace,
                          span: scope.service_entry_span,
                          response: gateway_response,
                          actions: result.actions
                        }

                        if scope.service_entry_span
                          scope.service_entry_span.set_tag('appsec.blocked', 'true') if result.actions.include?('block')
                          scope.service_entry_span.set_tag('appsec.event', 'true')
                        end

                        scope.processor_context.events << event
                      end
                    end

                    block = Rack::Reactive::Response.publish(op, gateway_response)
                  end

                  next [nil, [[:block, event]]] if block

                  ret, res = stack.call(gateway_response.response)

                  if event
                    res ||= []
                    res << [:monitor, event]
                  end

                  [ret, res]
                end
              end

              def watch_request_body(gateway = Instrumentation.gateway)
                gateway.watch('rack.request.body', :appsec) do |stack, gateway_request|
                  block = false

                  event = nil
                  scope = gateway_request.env[Datadog::AppSec::Ext::SCOPE_KEY]

                  AppSec::Reactive::Operation.new('rack.request.body') do |op|
                    Rack::Reactive::RequestBody.subscribe(op, scope.processor_context) do |result|
                      if result.status == :match
                        # TODO: should this hash be an Event instance instead?
                        event = {
                          waf_result: result,
                          trace: scope.trace,
                          span: scope.service_entry_span,
                          request: gateway_request,
                          actions: result.actions
                        }

                        if scope.service_entry_span
                          scope.service_entry_span.set_tag('appsec.blocked', 'true') if result.actions.include?('block')
                          scope.service_entry_span.set_tag('appsec.event', 'true')
                        end

                        scope.processor_context.events << event
                      end
                    end

                    block = Rack::Reactive::RequestBody.publish(op, gateway_request)
                  end

                  next [nil, [[:block, event]]] if block

                  ret, res = stack.call(gateway_request.request)

                  if event
                    res ||= []
                    res << [:monitor, event]
                  end

                  [ret, res]
                end
              end
            end
          end
        end
      end
    end
  end
end
