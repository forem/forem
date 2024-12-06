require_relative '../../../instrumentation/gateway'
require_relative '../../../reactive/operation'
require_relative '../reactive/action'
require_relative '../../../event'

module Datadog
  module AppSec
    module Contrib
      module Rails
        module Gateway
          # Watcher for Rails gateway events
          module Watcher
            class << self
              def watch
                gateway = Instrumentation.gateway

                watch_request_action(gateway)
              end

              def watch_request_action(gateway = Instrumentation.gateway)
                gateway.watch('rails.request.action', :appsec) do |stack, gateway_request|
                  block = false

                  event = nil
                  scope = gateway_request.env[Datadog::AppSec::Ext::SCOPE_KEY]

                  AppSec::Reactive::Operation.new('rails.request.action') do |op|
                    Rails::Reactive::Action.subscribe(op, scope.processor_context) do |result|
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

                    block = Rails::Reactive::Action.publish(op, gateway_request)
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
