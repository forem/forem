# frozen_string_literal: true

require_relative 'gateway/request'
require_relative '../../instrumentation/gateway'
require_relative '../../response'

module Datadog
  module AppSec
    module Contrib
      module Rack
        # Rack request body middleware for AppSec
        # This should be inserted just below Rack::JSONBodyParser or
        # legacy Rack::PostBodyContentTypeParser from rack-contrib
        class RequestBodyMiddleware
          def initialize(app, opt = {})
            @app = app
          end

          def call(env)
            context = env[Datadog::AppSec::Ext::SCOPE_KEY]

            return @app.call(env) unless context

            # TODO: handle exceptions, except for @app.call

            request_return, request_response = Instrumentation.gateway.push(
              'rack.request.body',
              Gateway::Request.new(env)
            ) do
              @app.call(env)
            end

            if request_response
              blocked_event = request_response.find { |action, _event| action == :block }
              request_return = AppSec::Response.negotiate(env, blocked_event.last[:actions]).to_rack if blocked_event
            end

            request_return
          end
        end
      end
    end
  end
end
