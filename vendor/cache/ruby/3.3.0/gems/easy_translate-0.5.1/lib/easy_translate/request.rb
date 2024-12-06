require 'net/http'
require 'net/https'
require 'uri'

module EasyTranslate

  class Request
    attr_accessor :http_options

    def initialize(options = {}, http_options = {})
      @options = options
      @http_options = http_options
    end

    # Body, blank by default
    # @return [String] The body for this request
    def body
      ''
    end

    # The path for the request
    # @return [String] The path for this request
    def path
      raise NotImplementedError.new('path is not implemented')
    end

    # The base params for a request
    # @return [Hash] a hash of the base parameters for any request
    def params
      params = {}
      params[:key] = EasyTranslate.api_key if EasyTranslate.api_key
      params[:prettyPrint] = 'false' # eliminate unnecessary overhead
      params
    end

    # Perform the given request
    # @return [String] The response String
    def perform_raw
      # Construct the request
      request = Net::HTTP::Post.new(uri.request_uri)
      request.add_field('X-HTTP-Method-Override', 'GET')
      request.body = body
      # Fire and return
      response = http.request(request)
      unless response.code == '200'
        err = JSON.parse(response.body)['error']['errors'].first['message']
        raise EasyTranslateException.new(err)
      end
      response.body
    end

    private

    def uri
      @uri ||= URI.parse("https://translation.googleapis.com#{path}?#{param_s}")
    end

    def http
      @http ||= Net::HTTP.new(uri.host, uri.port).tap do |http|
        configure_timeouts(http)
        configure_ssl(http)
      end
    end

    def configure_timeouts(http)
      http.read_timeout = http.open_timeout = http_options[:timeout] if http_options[:timeout]
      http.open_timeout = http_options[:open_timeout]                if http_options[:open_timeout]
    end

    def configure_ssl(http)
      http.use_ssl      = true
      http.verify_mode  = OpenSSL::SSL::VERIFY_PEER
      http.cert_store   = ssl_cert_store

      http.cert         = ssl_options[:client_cert]  if ssl_options[:client_cert]
      http.key          = ssl_options[:client_key]   if ssl_options[:client_key]
      http.ca_file      = ssl_options[:ca_file]      if ssl_options[:ca_file]
      http.ca_path      = ssl_options[:ca_path]      if ssl_options[:ca_path]
      http.verify_depth = ssl_options[:verify_depth] if ssl_options[:verify_depth]
      http.ssl_version  = ssl_options[:version]      if ssl_options[:version]
    end

    def ssl_cert_store
      return ssl_options[:cert_store] if ssl_options[:cert_store]
      # Use the default cert store by default, i.e. system ca certs
      cert_store = OpenSSL::X509::Store.new
      cert_store.set_default_paths
      cert_store
    end

    def ssl_options
      http_options[:ssl] || {}
    end

    # Stringify the params
    # @return [String] The params as a string
    def param_s
      params.map do |k, v|
        "#{k}=#{v}" unless v.nil?
      end.compact.join('&')
    end

  end

end
