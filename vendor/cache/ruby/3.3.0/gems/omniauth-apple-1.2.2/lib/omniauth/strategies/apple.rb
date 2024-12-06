# frozen_string_literal: true

require 'omniauth-oauth2'
require 'net/https'

module OmniAuth
  module Strategies
    class Apple < OmniAuth::Strategies::OAuth2
      class JWTFetchingFailed < CallbackError
        def initialize(error_reason = nil, error_uri = nil)
          super :jwks_fetching_failed, error_reason, error_uri
        end
      end

      option :name, 'apple'

      option :client_options,
             site: 'https://appleid.apple.com',
             authorize_url: '/auth/authorize',
             token_url: '/auth/token',
             auth_scheme: :request_body
      option :authorize_params,
             response_mode: 'form_post',
             scope: 'email name'
      option :authorized_client_ids, []

      uid { id_info['sub'] }

      # Documentation on parameters
      # https://developer.apple.com/documentation/sign_in_with_apple/sign_in_with_apple_rest_api/authenticating_users_with_sign_in_with_apple
      info do
        prune!(
          sub: id_info['sub'],
          email: email,
          first_name: first_name,
          last_name: last_name,
          name: (first_name || last_name) ? [first_name, last_name].join(' ') : email,
          email_verified: email_verified,
          is_private_email: is_private_email
        )
      end

      extra do
        id_token = request.params['id_token'] || access_token&.params&.dig('id_token')
        prune!(raw_info: {id_info: id_info, user_info: user_info, id_token: id_token})
      end

      def client
        ::OAuth2::Client.new(client_id, client_secret, deep_symbolize(options.client_options))
      end

      def email_verified
        value = id_info['email_verified']
        value == true || value == "true"
      end

      def is_private_email
        value = id_info['is_private_email']
        value == true || value == "true"
      end

      def authorize_params
        super.merge(nonce: new_nonce)
      end

      def callback_url
        options[:redirect_uri] || (full_host + callback_path)
      end

      private

      def new_nonce
        session['omniauth.nonce'] = SecureRandom.urlsafe_base64(16)
      end

      def stored_nonce
        session.delete('omniauth.nonce')
      end

      def id_info
        @id_info ||= if request.params&.key?('id_token') || access_token&.params&.key?('id_token')
                       id_token = request.params['id_token'] || access_token.params['id_token']
                       if (verification_key = fetch_jwks)
                         jwt_options = {
                           verify_iss: true,
                           iss: 'https://appleid.apple.com',
                           verify_iat: true,
                           verify_aud: true,
                           aud: [options.client_id].concat(options.authorized_client_ids),
                           algorithms: ['RS256'],
                           jwks: verification_key
                         }
                         payload, _header = ::JWT.decode(id_token, nil, true, jwt_options)
                         verify_nonce!(payload)
                         payload
                       else
                         {}
                       end
                     end
      end

      def fetch_jwks
        conn = Faraday.new(headers: {user_agent: 'ruby/omniauth-apple'}) do |c|
          c.response :json, parser_options: { symbolize_names: true }
          c.adapter Faraday.default_adapter
        end
        res = conn.get 'https://appleid.apple.com/auth/keys'
        if res.success?
          res.body
        else
          raise JWTFetchingFailed.new('HTTP Error when fetching JWKs')
        end
      rescue JWTFetchingFailed, Faraday::Error => e
        fail!(:jwks_fetching_failed, e) and nil
      end

      def verify_nonce!(payload)
        return unless payload['nonce_supported']

        return if payload['nonce'] && payload['nonce'] == stored_nonce

        fail!(:nonce_mismatch, CallbackError.new(:nonce_mismatch, 'nonce mismatch'))
      end

      def client_id
        @client_id ||= if id_info.nil?
                         options.client_id
                       else
                         id_info['aud'] if options.authorized_client_ids.include? id_info['aud']
                       end
      end

      def user_info
        user = request.params['user']
        return {} if user.nil?

        @user_info ||= JSON.parse(user)
      end

      def email
        id_info['email']
      end

      def first_name
        user_info.dig('name', 'firstName')
      end

      def last_name
        user_info.dig('name', 'lastName')
      end

      def prune!(hash)
        hash.delete_if do |_, v|
          prune!(v) if v.is_a?(Hash)
          v.nil? || (v.respond_to?(:empty?) && v.empty?)
        end
      end

      def client_secret
        payload = {
          iss: options.team_id,
          aud: 'https://appleid.apple.com',
          sub: client_id,
          iat: Time.now.to_i,
          exp: Time.now.to_i + 60
        }
        headers = { kid: options.key_id }

        ::JWT.encode(payload, private_key, 'ES256', headers)
      end

      def private_key
        ::OpenSSL::PKey::EC.new(options.pem)
      end
    end
  end
end
