require 'faraday'
require 'vcr/util/version_checker'
require 'vcr/request_handler'

VCR::VersionChecker.new('Faraday', Faraday::VERSION, '0.7.0').check_version!

module VCR
  # Contains middlewares for use with different libraries.
  module Middleware
    # Faraday middleware that VCR uses to record and replay HTTP requests made through
    # Faraday.
    #
    # @note You can either insert this middleware into the Faraday middleware stack
    #  yourself or configure {VCR::Configuration#hook_into} to hook into `:faraday`.
    class Faraday
      include VCR::Deprecations::Middleware::Faraday

      # Constructs a new instance of the Faraday middleware.
      #
      # @param [#call] app the faraday app
      def initialize(app)
        super
        @app = app
      end

      # Handles the HTTP request being made through Faraday
      #
      # @param [Hash] env the Faraday request env hash
      def call(env)
        return @app.call(env) if VCR.library_hooks.disabled?(:faraday)
        RequestHandler.new(@app, env).handle
      end

      # Close any persistent connections.
      def close
        @app.close if @app.respond_to?(:close)
      end

      # @private
      class RequestHandler < ::VCR::RequestHandler
        attr_reader :app, :env
        def initialize(app, env)
          @app, @env = app, env
          @has_on_complete_hook = false
        end

        def handle
          # Faraday must be exclusive here in case another library hook is being used.
          # We don't want double recording/double playback.
          VCR.library_hooks.exclusive_hook = :faraday
          collect_chunks if env.request.stream_response?

          super
        ensure
          response = defined?(@vcr_response) ? @vcr_response : nil
          invoke_after_request_hook(response) unless delay_finishing?
        end

      private

        def delay_finishing?
          !!env[:parallel_manager] && @has_on_complete_hook
        end

        def vcr_request
          @vcr_request ||= VCR::Request.new \
            env[:method],
            env[:url].to_s,
            raw_body_from(env[:body]),
            env[:request_headers]
        end

        def raw_body_from(body)
          return body unless body.respond_to?(:read)

          body.read.tap do |b|
            body.rewind if body.respond_to?(:rewind)
          end
        end

        def response_for(response)
          # reason_phrase is a new addition to Faraday::Response,
          # so maintain backward compatibility
          reason = response.respond_to?(:reason_phrase) ? response.reason_phrase : nil

          VCR::Response.new(
            VCR::ResponseStatus.new(response.status, reason),
            response.headers,
            raw_body_from(response.body),
            nil
          )
        end

        def on_ignored_request
          response = app.call(env)
          @vcr_response = response_for(response)
          response
        end

        def on_stubbed_by_vcr_request
          headers = env[:response_headers] ||= ::Faraday::Utils::Headers.new
          headers.update stubbed_response.headers if stubbed_response.headers
          env.update :status => stubbed_response.status.code, :body => stubbed_response.body

          @vcr_response = stubbed_response

          faraday_response = ::Faraday::Response.new
          env.request.on_data.call(stubbed_response.body, stubbed_response.body.length) if env.request.stream_response?
          faraday_response.finish(env)
          env[:response] = faraday_response
        end

        def on_recordable_request
          @has_on_complete_hook = true
          response = app.call(env)
          response.on_complete do
            restore_body_from_chunks(env.request) if env.request.stream_response?
            @vcr_response = response_for(response)
            VCR.record_http_interaction(VCR::HTTPInteraction.new(vcr_request, @vcr_response))
            invoke_after_request_hook(@vcr_response) if delay_finishing?
          end
        end

        def invoke_after_request_hook(response)
          super
          VCR.library_hooks.exclusive_hook = nil
        end

        def collect_chunks
          caller_on_data = env.request.on_data
          chunks = ''
          env.request.on_data = Proc.new do |chunk, overall_received_bytes|
            chunks += chunk
            env.request.instance_variable_set(:@chunked_body, chunks)
            caller_on_data.call(chunk, overall_received_bytes)
          end
        end

        def restore_body_from_chunks(request)
          env[:body] = request.instance_variable_get(:@chunked_body)
        end
      end
    end
  end
end
