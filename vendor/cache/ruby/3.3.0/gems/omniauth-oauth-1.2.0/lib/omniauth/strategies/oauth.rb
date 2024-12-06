require "oauth"
require "omniauth"

module OmniAuth
  module Strategies
    class OAuth
      include OmniAuth::Strategy

      args [:consumer_key, :consumer_secret]
      option :consumer_key, nil
      option :consumer_secret, nil
      option :client_options, {}
      option :open_timeout, 30
      option :read_timeout, 30
      option :authorize_params, {}
      option :request_params, {}

      attr_reader :access_token

      def consumer
        consumer = ::OAuth::Consumer.new(options.consumer_key, options.consumer_secret, options.client_options)
        consumer.http.open_timeout = options.open_timeout if options.open_timeout
        consumer.http.read_timeout = options.read_timeout if options.read_timeout
        consumer
      end

      def request_phase # rubocop:disable MethodLength
        request_token = consumer.get_request_token({:oauth_callback => callback_url}, options.request_params)
        session["oauth"] ||= {}
        session["oauth"][name.to_s] = {"callback_confirmed" => request_token.callback_confirmed?, "request_token" => request_token.token, "request_secret" => request_token.secret}

        if request_token.callback_confirmed?
          redirect request_token.authorize_url(options[:authorize_params])
        else
          redirect request_token.authorize_url(options[:authorize_params].merge(:oauth_callback => callback_url))
        end

      rescue ::Timeout::Error => e
        fail!(:timeout, e)
      rescue ::Net::HTTPFatalError, ::OpenSSL::SSL::SSLError => e
        fail!(:service_unavailable, e)
      end

      def callback_phase # rubocop:disable MethodLength
        fail(OmniAuth::NoSessionError, "Session Expired") if session["oauth"].nil?

        request_token = ::OAuth::RequestToken.new(consumer, session["oauth"][name.to_s].delete("request_token"), session["oauth"][name.to_s].delete("request_secret"))

        opts = {}
        if session["oauth"][name.to_s]["callback_confirmed"]
          opts[:oauth_verifier] = request["oauth_verifier"]
        else
          opts[:oauth_callback] = callback_url
        end

        @access_token = request_token.get_access_token(opts)
        super
      rescue ::Timeout::Error => e
        fail!(:timeout, e)
      rescue ::Net::HTTPFatalError, ::OpenSSL::SSL::SSLError => e
        fail!(:service_unavailable, e)
      rescue ::OAuth::Unauthorized => e
        fail!(:invalid_credentials, e)
      rescue ::OmniAuth::NoSessionError => e
        fail!(:session_expired, e)
      end

      credentials do
        {"token" => access_token.token, "secret" => access_token.secret}
      end

      extra do
        {"access_token" => access_token}
      end
    end
  end
end

OmniAuth.config.add_camelization "oauth", "OAuth"
