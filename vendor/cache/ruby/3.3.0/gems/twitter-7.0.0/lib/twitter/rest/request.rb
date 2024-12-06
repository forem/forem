require 'addressable/uri'
require 'http'
require 'http/form_data'
require 'json'
require 'openssl'
require 'twitter/error'
require 'twitter/headers'
require 'twitter/rate_limit'
require 'twitter/utils'

module Twitter
  module REST
    class Request # rubocop:disable Metrics/ClassLength
      include Twitter::Utils
      BASE_URL = 'https://api.twitter.com'.freeze
      attr_accessor :client, :headers, :options, :path, :rate_limit,
                    :request_method, :uri
      alias verb request_method

      # @param client [Twitter::Client]
      # @param request_method [String, Symbol]
      # @param path [String]
      # @param options [Hash]
      # @return [Twitter::REST::Request]
      def initialize(client, request_method, path, options = {}, params = nil)
        @client = client
        @uri = Addressable::URI.parse(path.start_with?('http') ? path : BASE_URL + path)
        multipart_options = params || options
        set_multipart_options!(request_method, multipart_options)
        @path = uri.path
        @options = options
        @options_key = {get: :params, json_post: :json, json_put: :json, delete: :params}[request_method] || :form
        @params = params
      end

      # @return [Array, Hash]
      def perform
        response = http_client.headers(@headers).public_send(@request_method, @uri.to_s, request_options)
        response_body = response.body.empty? ? '' : symbolize_keys!(response.parse)
        response_headers = response.headers
        fail_or_return_response_body(response.code, response_body, response_headers)
      end

    private

      def request_options
        options = {@options_key => @options}
        if @params
          if options[:params]
            options[:params].merge(@params)
          else
            options[:params] = @params
          end
        end
        options
      end

      def merge_multipart_file!(options)
        key = options.delete(:key)
        file = options.delete(:file)

        options[key] = if file.is_a?(StringIO)
                         HTTP::FormData::File.new(file, content_type: 'video/mp4')
                       else
                         HTTP::FormData::File.new(file, filename: File.basename(file), content_type: content_type(File.basename(file)))
                       end
      end

      def set_multipart_options!(request_method, options)
        if %i[multipart_post json_post].include?(request_method)
          merge_multipart_file!(options) if request_method == :multipart_post
          options = {}
          @request_method = :post
        elsif request_method == :json_put
          @request_method = :put
        else
          @request_method = request_method
        end
        @headers = Twitter::Headers.new(@client, @request_method, @uri, options).request_headers
      end

      def content_type(basename)
        case basename
        when /\.gif$/i
          'image/gif'
        when /\.jpe?g/i
          'image/jpeg'
        when /\.png$/i
          'image/png'
        else
          'application/octet-stream'
        end
      end

      def fail_or_return_response_body(code, body, headers)
        error = error(code, body, headers)
        raise(error) if error

        @rate_limit = Twitter::RateLimit.new(headers)
        body
      end

      def error(code, body, headers)
        klass = Twitter::Error::ERRORS[code]
        if klass == Twitter::Error::Forbidden
          forbidden_error(body, headers)
        elsif !klass.nil?
          klass.from_response(body, headers)
        elsif body&.is_a?(Hash) && (err = body.dig(:processing_info, :error))
          Twitter::Error::MediaError.from_processing_response(err, headers)
        end
      end

      def forbidden_error(body, headers)
        error = Twitter::Error::Forbidden.from_response(body, headers)
        klass = Twitter::Error::FORBIDDEN_MESSAGES[error.message]
        if klass
          klass.from_response(body, headers)
        else
          error
        end
      end

      def symbolize_keys!(object)
        if object.is_a?(Array)
          object.each_with_index do |val, index|
            object[index] = symbolize_keys!(val)
          end
        elsif object.is_a?(Hash)
          object.dup.each_key do |key|
            object[key.to_sym] = symbolize_keys!(object.delete(key))
          end
        end
        object
      end

      # Returns boolean indicating if all the keys required by HTTP::Client are present in Twitter::Client#timeouts
      #
      # @return [Boolean]
      def timeout_keys_defined
        (%i[write connect read] - (@client.timeouts&.keys || [])).empty?
      end

      # @return [HTTP::Client, HTTP]
      def http_client
        client = @client.proxy ? HTTP.via(*proxy) : HTTP
        client = client.timeout(connect: @client.timeouts[:connect], read: @client.timeouts[:read], write: @client.timeouts[:write]) if timeout_keys_defined
        client
      end

      # Return proxy values as a compacted array
      #
      # @return [Array]
      def proxy
        @client.proxy.values_at(:host, :port, :username, :password).compact
      end
    end
  end
end
