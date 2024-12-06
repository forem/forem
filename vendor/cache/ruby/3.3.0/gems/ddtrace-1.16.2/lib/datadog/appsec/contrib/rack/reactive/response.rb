# frozen_string_literal: true

module Datadog
  module AppSec
    module Contrib
      module Rack
        module Reactive
          # Dispatch data from a Rack response to the WAF context
          module Response
            ADDRESSES = [
              'response.status',
              'response.headers',
            ].freeze
            private_constant :ADDRESSES

            def self.publish(op, gateway_response)
              catch(:block) do
                op.publish('response.status', gateway_response.status)
                op.publish('response.headers', gateway_response.headers)

                nil
              end
            end

            def self.subscribe(op, waf_context)
              op.subscribe(*ADDRESSES) do |*values|
                Datadog.logger.debug { "reacted to #{ADDRESSES.inspect}: #{values.inspect}" }

                response_status = values[0]
                response_headers = values[1]
                response_headers_no_cookies = response_headers.dup.tap { |h| h.delete('set-cookie') }

                waf_args = {
                  'server.response.status' => response_status.to_s,
                  'server.response.headers' => response_headers,
                  'server.response.headers.no_cookies' => response_headers_no_cookies,
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
