require 'excon'
require 'vcr/request_handler'
require 'vcr/util/version_checker'

VCR::VersionChecker.new('Excon', Excon::VERSION, '0.25.2').check_version!

module VCR
  # Contains middlewares for use with different libraries.
  module Middleware
    # Contains Excon middlewares.
    module Excon
      # One part of the Excon middleware that uses VCR to record
      # and replay HTTP requests made through Excon.
      #
      # @private
      class Request < ::Excon::Middleware::Base
        # @private
        def request_call(params)
          params[:vcr_request_handler] = request_handler = RequestHandler.new
          request_handler.before_request(params)

          super
        end
      end

      # One part of the Excon middleware that uses VCR to record
      # and replay HTTP requests made through Excon.
      #
      # @private
      class Response < ::Excon::Middleware::Base
        # @private
        def response_call(params)
          complete_request(params)
          super
        end

        def error_call(params)
          complete_request(params)
          super
        end

      private

        def complete_request(params)
          if handler = params.delete(:vcr_request_handler)
            handler.after_request(params[:response])
          end
        end
      end

      # Handles a single Excon request.
      #
      # @private
      class RequestHandler < ::VCR::RequestHandler
        def initialize
          @request_params       = nil
          @response_body_reader = nil
          @should_record        = false
        end

        # Performs before_request processing based on the provided
        # request_params.
        #
        # @private
        def before_request(request_params)
          @request_params       = request_params
          @response_body_reader = create_response_body_reader
          handle
        end

        # Performs after_request processing based on the provided response.
        #
        # @private
        def after_request(response)
          vcr_response = vcr_response_for(response)

          if vcr_response && should_record?
            VCR.record_http_interaction(VCR::HTTPInteraction.new(vcr_request, vcr_response))
          end

          invoke_after_request_hook(vcr_response)
        end

        def ensure_response_body_can_be_read_for_error_case
          # Excon does not invoke the `:response_block` when an error
          # has occurred, so we need to be sure to use the non-streaming
          # body reader.
          @response_body_reader = NonStreamingResponseBodyReader
        end

        attr_reader :request_params, :response_body_reader

      private

        def externally_stubbed?
          !!::Excon.stub_for(request_params)
        end

        def should_record?
          @should_record
        end

        def on_stubbed_by_vcr_request
          request_params[:response] = {
            :body     => stubbed_response.body.dup, # Excon mutates the body, so we must dup it :-(
            :headers  => normalized_headers(stubbed_response.headers || {}),
            :status   => stubbed_response.status.code
          }
        end

        def on_recordable_request
          @should_record = true
        end

        def create_response_body_reader
          block = request_params[:response_block]
          return NonStreamingResponseBodyReader unless block

          StreamingResponseBodyReader.new(block).tap do |response_block_wrapper|
            request_params[:response_block] = response_block_wrapper
          end
        end

        def vcr_request
          @vcr_request ||= begin
            headers = request_params[:headers].dup
            headers.delete("Host")

            VCR::Request.new \
              request_params[:method],
              uri,
              request_params[:body],
              headers
          end
        end

        def vcr_response_for(response)
          return nil if response.nil?

          VCR::Response.new(
            VCR::ResponseStatus.new(response.fetch(:status), nil),
            response.fetch(:headers),
            response_body_reader.read_body_from(response),
            nil
          )
        end

        def normalized_headers(headers)
          normalized = {}
          headers.each do |k, v|
            v = v.join(', ') if v.respond_to?(:join)
            normalized[k] = v
          end
          normalized
        end

        if defined?(::Excon::Utils) && ::Excon::Utils.respond_to?(:request_uri)
          def uri
            @uri ||= "#{::Excon::Utils.request_uri(request_params)}"
          end
        else
          require 'vcr/middleware/excon/legacy_methods'
          include LegacyMethods

          def uri
            @uri ||= "#{request_params[:scheme]}://#{request_params[:host]}:#{request_params[:port]}#{request_params[:path]}#{query}"
          end
        end
      end

      # Wraps an Excon streaming `:response_block`, so that we can
      # accumulate the response as it streams back from the real HTTP
      # server in order to record it.
      #
      # @private
      class StreamingResponseBodyReader
        def initialize(response_block)
          @response_block = response_block
          @chunks = []
        end

        # @private
        def call(chunk, remaining_bytes, total_bytes)
          @chunks << chunk
          @response_block.call(chunk, remaining_bytes, total_bytes)
        end

        # Provides a duck-typed interface that matches that of
        # `NonStreamingResponseBodyReader`. The request handler
        # will use this to get the response body.
        #
        # @private
        def read_body_from(response_params)
          if @chunks.none?
            # Not sure why, but sometimes the body comes through the params
            # instead of via the streaming block even when the block was
            # configured.
            response_params[:body]
          else
            @chunks.join('')
          end
        end
      end

      # Reads the body when no streaming is done.
      #
      # @private
      class NonStreamingResponseBodyReader
        # Provides a duck-typed interface that matches that of
        # `StreamingResponseBodyReader`. The request handler
        # will use this to get the response body.
        #
        # @private
        def self.read_body_from(response_params)
          response_params.fetch(:body)
        end
      end
    end
  end
end

