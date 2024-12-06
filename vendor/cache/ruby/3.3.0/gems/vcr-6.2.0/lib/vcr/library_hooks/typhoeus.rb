require 'vcr/util/version_checker'
require 'vcr/request_handler'
require 'typhoeus'

module VCR
  class LibraryHooks
    # @private
    module Typhoeus
      # @private
      class RequestHandler < ::VCR::RequestHandler
        attr_reader :request
        def initialize(request)
          @request = request
          request.block_connection = false if VCR.turned_on?
        end

        def vcr_request
          @vcr_request ||= VCR::Request.new \
            request.options.fetch(:method, :get),
            request.url,
            request.encoded_body,
            request.options.fetch(:headers, {})
        end

      private

        def externally_stubbed?
          ::Typhoeus::Expectation.find_by(request)
        end

        def set_typed_request_for_after_hook(*args)
          super
          request.instance_variable_set(:@__typed_vcr_request, @after_hook_typed_request)
        end

        def on_unhandled_request
          invoke_after_request_hook(nil)
          super
        end

        def on_stubbed_by_vcr_request
          response = ::Typhoeus::Response.new \
            :http_version   => stubbed_response.http_version,
            :code           => stubbed_response.status.code,
            :status_message => stubbed_response.status.message,
            :headers        => stubbed_response_headers,
            :body           => stubbed_response.body,
            :effective_url  => stubbed_response.adapter_metadata.fetch('effective_url', request.url),
            :mock           => true

          first_header_line = "HTTP/#{stubbed_response.http_version} #{response.code} #{response.status_message}\r\n"
          response.instance_variable_set(:@first_header_line, first_header_line)
          response.instance_variable_get(:@options)[:response_headers] =
            first_header_line + response.headers.map { |k,v| "#{k}: #{v}"}.join("\r\n")

          response
        end

        def stubbed_response_headers
          @stubbed_response_headers ||= {}.tap do |hash|
            stubbed_response.headers.each do |key, values|
              hash[key] = values.size == 1 ? values.first : values
            end if stubbed_response.headers
          end
        end
      end

      # @private
      class << self
        def vcr_response_from(response)
          VCR::Response.new \
            VCR::ResponseStatus.new(response.code, response.status_message),
            response.headers,
            response.body,
            response.http_version,
            { "effective_url" => response.effective_url }
        end

        def collect_chunks(request)
          chunks = ''
          request.on_body.unshift(
            Proc.new do |body, response|
              chunks += body
              request.instance_variable_set(:@chunked_body, chunks)
            end
          )
        end

        def restore_body_from_chunks(response, request)
          response.options[:response_body] = request.instance_variable_get(:@chunked_body)
        end
      end

      ::Typhoeus.on_complete do |response|
        request = response.request

        restore_body_from_chunks(response, request) if request.streaming?

        unless VCR.library_hooks.disabled?(:typhoeus)
          vcr_response = vcr_response_from(response)
          typed_vcr_request = request.send(:remove_instance_variable, :@__typed_vcr_request)

          unless request.response.mock
            http_interaction = VCR::HTTPInteraction.new(typed_vcr_request, vcr_response)
            VCR.record_http_interaction(http_interaction)
          end

          VCR.configuration.invoke_hook(:after_http_request, typed_vcr_request, vcr_response)
        end
      end

      ::Typhoeus.before do |request|
        collect_chunks(request) if request.streaming?
        if response = VCR::LibraryHooks::Typhoeus::RequestHandler.new(request).handle
          request.on_headers.each { |cb| cb.call(response) }
          request.on_body.each { |cb| cb.call(response.body, response) }
          request.finish(response)
        else
          true
        end
      end
    end
  end
end

VCR.configuration.after_library_hooks_loaded do
  # ensure WebMock's Typhoeus adapter does not conflict with us here
  # (i.e. to double record requests or whatever).
  if defined?(WebMock::HttpLibAdapters::TyphoeusAdapter)
    WebMock::HttpLibAdapters::TyphoeusAdapter.disable!
  end
end
