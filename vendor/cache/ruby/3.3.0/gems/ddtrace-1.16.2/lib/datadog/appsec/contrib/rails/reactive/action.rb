# frozen_string_literal: true

require_relative '../request'

module Datadog
  module AppSec
    module Contrib
      module Rails
        module Reactive
          # Dispatch data from a Rails request to the WAF context
          module Action
            ADDRESSES = [
              'rails.request.body',
              'rails.request.route_params',
            ].freeze
            private_constant :ADDRESSES

            def self.publish(op, gateway_request)
              catch(:block) do
                # params have been parsed from the request body
                op.publish('rails.request.body', gateway_request.parsed_body)
                op.publish('rails.request.route_params', gateway_request.route_params)

                nil
              end
            end

            def self.subscribe(op, waf_context)
              op.subscribe(*ADDRESSES) do |*values|
                Datadog.logger.debug { "reacted to #{ADDRESSES.inspect}: #{values.inspect}" }
                body = values[0]
                path_params = values[1]

                waf_args = {
                  'server.request.body' => body,
                  'server.request.path_params' => path_params,
                }

                waf_timeout = Datadog.configuration.appsec.waf_timeout
                result = waf_context.run(waf_args, waf_timeout)

                Datadog.logger.debug { "WAF TIMEOUT: #{result.inspect}" } if result.timeout

                case result.status
                when :match
                  Datadog.logger.debug { "WAF: #{result.inspect}" }

                  yield result
                  throw(:block, true) unless result.actions.empty?
                when :ok
                  Datadog.logger.debug { "WAF OK: #{result.inspect}" }
                when :invalid_call
                  Datadog.logger.debug { "WAF CALL ERROR: #{result.inspect}" }
                when :invalid_rule, :invalid_flow, :no_rule
                  Datadog.logger.debug { "WAF RULE ERROR: #{result.inspect}" }
                else
                  Datadog.logger.debug { "WAF UNKNOWN: #{result.status.inspect} #{result.inspect}" }
                end
              end
            end
          end
        end
      end
    end
  end
end
