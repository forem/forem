# frozen_string_literal: true

module Solargraph
  module LanguageServer
    module Message
      class Base
        # @return [Solargraph::LanguageServer::Host]
        attr_reader :host

        # @return [Integer]
        attr_reader :id

        # @return [Hash]
        attr_reader :request

        # @return [String]
        attr_reader :method

        # @return [Hash]
        attr_reader :params

        # @return [Hash, Array, nil]
        attr_reader :result

        # @return [Hash, nil]
        attr_reader :error

        # @param host [Solargraph::LanguageServer::Host]
        # @param request [Hash]
        def initialize host, request
          @host = host
          @id = request['id'].freeze
          @request = request.freeze
          @method = request['method'].freeze
          @params = (request['params'] || {}).freeze
          post_initialize
        end

        # @return [void]
        def post_initialize; end

        # @return [void]
        def process; end

        # @param data [Hash, Array, nil]
        # @return [void]
        def set_result data
          @result = data
        end

        # @param code [Integer] See Solargraph::LanguageServer::ErrorCodes
        # @param message [String]
        # @return [void]
        def set_error code, message
          @error = {
            code: code,
            message: message
          }
        end

        # @return [void]
        def send_response
          return if id.nil?
          if host.cancel?(id)
            # https://microsoft.github.io/language-server-protocol/specifications/specification-current/#cancelRequest
            # cancel should send response RequestCancelled
            Solargraph::Logging.logger.info "Cancelled response to #{method}"
            set_result nil
            set_error ErrorCodes::REQUEST_CANCELLED, "cancelled by client"
          else
            Solargraph::Logging.logger.info "Sending response to #{method}"
          end
          response = {
            jsonrpc: "2.0",
            id: id,
          }
          response[:result] = result unless result.nil?
          response[:error] = error unless error.nil?
          response[:result] = nil if result.nil? and error.nil?
          json = response.to_json
          envelope = "Content-Length: #{json.bytesize}\r\n\r\n#{json}"
          Solargraph.logger.debug envelope
          host.queue envelope
          host.clear id
        end
      end
    end
  end
end
