require "net/http"

module DelegatedAccess
  class JwksClient
    Error = Class.new(StandardError)

    class NetHttpAdapter
      Response = Struct.new(:status, :headers, :body, keyword_init: true)

      OPEN_TIMEOUT_SECONDS = 2
      READ_TIMEOUT_SECONDS = 2
      MAX_RESPONSE_BYTES = 65_536
      private_constant :OPEN_TIMEOUT_SECONDS, :READ_TIMEOUT_SECONDS, :MAX_RESPONSE_BYTES

      def get(uri, headers:)
        request = Net::HTTP::Get.new(uri.request_uri, headers)
        response_headers = nil
        response_body = +""
        status = nil

        Net::HTTP.start(
          uri.host,
          uri.port,
          use_ssl: true,
          open_timeout: OPEN_TIMEOUT_SECONDS,
          read_timeout: READ_TIMEOUT_SECONDS,
        ) do |http|
          http.max_retries = 0
          http.request(request) do |response|
            status = response.code.to_i
            response_headers = response.each_header.to_h
            response.read_body do |chunk|
              response_body << chunk
              raise Error, "JWKS response is too large" if response_body.bytesize > MAX_RESPONSE_BYTES
            end
          end
        end

        Response.new(status: status, headers: response_headers, body: response_body.freeze)
      rescue Net::OpenTimeout, Net::ReadTimeout, OpenSSL::SSL::SSLError, SocketError, SystemCallError, IOError => e
        raise Error, e.class.name
      end
    end

    def initialize(uri:, adapter: NetHttpAdapter.new)
      @uri = uri
      @adapter = adapter
    end

    def fetch
      response = adapter.get(
        uri,
        headers: {
          "Accept" => "application/json",
          "User-Agent" => "Forem delegated-access JWKS verifier"
        },
      )
      raise Error, "unexpected JWKS response status" unless response.status == 200

      content_type = response.headers.fetch("content-type", "")
      raise Error, "JWKS response is not JSON" unless content_type.split(";", 2).first == "application/json"

      response.body
    rescue Error
      raise
    rescue StandardError => e
      raise Error, e.class.name
    end

    private

    attr_reader :adapter, :uri
  end
end
