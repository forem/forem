module Fog
  module XML
    class SAXParserConnection < ::Fog::Core::Connection
      # Makes a request using the connection using Excon
      #
      # @param [Hash] params
      # @option params [String] :body text to be sent over a socket
      # @option params [Hash<Symbol, String>] :headers The default headers to supply in a request
      # @option params [String] :host The destination host"s reachable DNS name or IP, in the form of a String
      # @option params [String] :path appears after "scheme://host:port/"
      # @option params [Fixnum] :port The port on which to connect, to the destination host
      # @option params [Hash]   :query appended to the "scheme://host:port/path/" in the form of "?key=value"
      # @option params [String] :scheme The protocol; "https" causes OpenSSL to be used
      # @option params [Proc] :response_block
      # @option params [Nokogiri::XML::SAX::Document] :parser
      #
      # @return [Excon::Response]
      #
      # @raise [Excon::Errors::StubNotFound]
      # @raise [Excon::Errors::Timeout]
      # @raise [Excon::Errors::SocketError]
      #
      def request(parser, params)
        reset unless @persistent

        params[:response_block] = ::Fog::XML::Response.new(parser)

        # Make request which read chunks into parser
        response = @excon.request(params)

        # Cease parsing and override response.body with parsed data
        params[:response_block].finish
        response.body = parser.response
        response
      end
    end
  end
end
