# frozen_string_literal: true

require 'json'
require 'cgi'
require 'net/http' # also requires uri
require 'openssl'

class Fastly
  # The UserAgent to communicate with the API
  class Client #:nodoc: all

    DEFAULT_URL = 'https://api.fastly.com'.freeze

    attr_accessor :api_key, :base_url, :debug, :user, :password, :customer

    def initialize(opts)
      @api_key            = opts.fetch(:api_key, nil)
      @base_url           = opts.fetch(:base_url, DEFAULT_URL)
      @customer           = opts.fetch(:customer, nil)
      @oldpurge           = opts.fetch(:use_old_purge_method, false)
      @password           = opts.fetch(:password, nil)
      @user               = opts.fetch(:user, nil)
      @debug              = opts.fetch(:debug, nil)
      @thread_http_client = if defined?(Concurrent::ThreadLocalVar)
                              Concurrent::ThreadLocalVar.new { build_http_client }
                            end

      if api_key.nil?
        fail Unauthorized, "Invalid auth credentials. Check api_key."
      end

      self
    end

    def require_key!
      raise Fastly::KeyAuthRequired.new("This request requires an API key") if api_key.nil?
      @require_key = true
    end

    def require_key?
      !!@require_key
    end

    def authed?
      !api_key.nil? || fully_authed?
    end

    # Some methods require full username and password rather than just auth token
    def fully_authed?
      !(user.nil? || password.nil?)
    end

    def get(path, params = {})
      extras = params.delete(:headers) || {}
      include_auth = params.key?(:include_auth) ? params.delete(:include_auth) : true
      path += "?#{make_params(params)}" unless params.empty?
      resp  = http.get(path, headers(extras, include_auth))
      fail Error, resp.body unless resp.kind_of?(Net::HTTPSuccess)
      JSON.parse(resp.body)
    end

    def get_stats(path, params = {})
      resp = get(path, params)

      # return meta data, not just the actual stats data
      if resp['status'] == 'success'
        resp
      else
        fail Error, resp['msg']
      end
    end

    def post(path, params = {})
      post_and_put(:post, path, params)
    end

    def put(path, params = {})
      post_and_put(:put, path, params)
    end

    def delete(path, params = {})
      extras = params.delete(:headers) || {}
      include_auth = params.key?(:include_auth) ? params.delete(:include_auth) : true
      resp  = http.delete(path, headers(extras, include_auth))
      resp.kind_of?(Net::HTTPSuccess)
    end

    def purge(url, params = {})
      return post("/purge/#{url}", params) if @oldpurge

      extras = params.delete(:headers) || {}
      uri    = URI.parse(url)
      http   = Net::HTTP.new(uri.host, uri.port)

      if uri.is_a? URI::HTTPS
        http.use_ssl = true
      end

      resp   = http.request Net::HTTP::Purge.new(uri.request_uri, headers(extras))

      fail Error, resp.body unless resp.kind_of?(Net::HTTPSuccess)
      JSON.parse(resp.body)
    end

    def http
      return @thread_http_client.value if @thread_http_client
      return Thread.current[:fastly_net_http] if Thread.current[:fastly_net_http]

      Thread.current[:fastly_net_http] = build_http_client
    end

    private

    def build_http_client
      uri      = URI.parse(base_url)
      net_http = Net::HTTP.new(uri.host, uri.port, :ENV, nil, nil, nil)

      # handle TLS connections outside of development
      net_http.verify_mode = OpenSSL::SSL::VERIFY_PEER
      net_http.use_ssl     = uri.scheme.downcase == 'https'

      # debug http interactions if specified
      net_http.set_debug_output(debug) if debug

      net_http
    end

    def post_and_put(method, path, params = {})
      extras = params.delete(:headers) || {}
      include_auth = params.key?(:include_auth) ? params.delete(:include_auth) : true
      query = make_params(params)
      resp  = http.send(method, path, query, headers(extras, include_auth).merge('Content-Type' =>  'application/x-www-form-urlencoded'))
      fail Error, resp.body unless resp.kind_of?(Net::HTTPSuccess)
      JSON.parse(resp.body)
    end

    def headers(extras={}, include_auth=true)
      headers = {}
      if include_auth
        headers['Fastly-Key'] = api_key if api_key
      end
      headers.merge('Content-Accept' => 'application/json', 'User-Agent' => "fastly-ruby-v#{Fastly::VERSION}").merge(extras.keep_if {|k,v| !v.nil? })
    end

    def make_params(params)
      param_ary = params.map do |key, value|
        next if value.nil?
        key = key.to_s

        if value.is_a?(Hash)
          value.map do |sub_key, sub_value|
            "#{CGI.escape("#{key}[#{sub_key}]")}=#{CGI.escape(sub_value.to_s)}"
          end
        else
          "#{CGI.escape(key)}=#{CGI.escape(value.to_s)}"
        end
      end

      param_ary.flatten.delete_if { |v| v.nil? }.join('&')
    end
  end
end

# See Net::HTTPGenericRequest for attributes and methods.
class Net::HTTP::Purge < Net::HTTPRequest
  METHOD = 'PURGE'
  REQUEST_HAS_BODY = false
  RESPONSE_HAS_BODY = true
end
