#!/usr/bin/env ruby
# frozen_string_literal: true

# Minimal APNs client (JWT-based HTTP/2 push) for dry-run/on-demand testing.
# Initially supports DRY_RUN logging only; real network send will be added
# after APNs credentials (.p8) are provisioned.

require 'json'
require 'openssl'
require 'base64'
require 'net/http'
require 'uri'

module Push
  class ApnsClient
    APNS_ENDPOINTS = {
      'development' => 'https://api.sandbox.push.apple.com',
      'production'  => 'https://api.push.apple.com'
    }.freeze

    attr_reader :team_id, :key_id, :bundle_id, :environment, :p8_path

    def initialize(team_id:, key_id:, bundle_id:, p8_path:, environment: ENV['APNS_ENV'] || 'development')
      @team_id     = team_id
      @key_id      = key_id
      @bundle_id   = bundle_id
      @p8_path     = p8_path
      @environment = environment
    end

    # Dry-run only: builds headers/payload and returns them without sending unless dry_run: false and IOS_PUSH_ENABLED present.
    def send_token(token:, title:, body:, data: {}, dry_run: true)
      jwt = build_jwt
      payload = build_payload(title: title, body: body, data: data)
      headers = build_headers(jwt: jwt, token: token)

      if dry_run || !ios_push_enabled?
        return { status: :dry_run, endpoint: endpoint_url(token), headers: headers, payload: payload }
      end

      perform_http2_request(token: token, jwt: jwt, payload: payload, headers: headers)
    end

    private

    def ios_push_enabled?
      ENV['IOS_PUSH_ENABLED'] == 'true'
    end

    def endpoint_url(token)
      base = APNS_ENDPOINTS.fetch(environment, APNS_ENDPOINTS['development'])
      URI("#{base}/3/device/#{token}")
    end

    def build_payload(title:, body:, data: {})
      aps = {
        'alert' => { 'title' => title, 'body' => body },
        'sound' => 'default'
      }
      aps['content-available'] = 1 if data && !data.empty?
      { 'aps' => aps }.merge(data.transform_keys(&:to_s))
    end

    def build_headers(jwt:, token: nil)
      {
        'authorization' => "bearer #{jwt}",
        'apns-topic'    => bundle_id,
        'apns-push-type' => 'alert'
      }.tap do |h|
        h['apns-priority'] = '10'
      end
    end

    def build_jwt
      private_key = OpenSSL::PKey::EC.new(File.read(p8_path))
      header = { 'alg' => 'ES256', 'kid' => key_id } # Apple's APNs JWT header spec
      claims = { 'iss' => team_id, 'iat' => Time.now.to_i }
      base64_header = urlsafe_base64(header.to_json)
      base64_claims = urlsafe_base64(claims.to_json)
      signature_input = "#{base64_header}.#{base64_claims}"
      signature = private_key.dsa_sign_asn1(Digest::SHA256.digest(signature_input))
      base64_signature = urlsafe_base64(signature)
      [base64_header, base64_claims, base64_signature].join('.')
    end

    def urlsafe_base64(str)
      Base64.urlsafe_encode64(str).delete('=')
    end

    # Placeholder for real HTTP/2 send; using Net::HTTP temporarily (will upgrade to http/2 gem if needed).
    def perform_http2_request(token:, jwt:, payload:, headers: {})
      # NOTE: Net::HTTP does not support HTTP/2; this is a placeholder stub.
      # Implementation will switch to a proper HTTP/2 client (e.g., httpx) later.
      { status: :not_implemented, message: 'HTTP/2 send not yet implemented; still in dry-run phase', token: token }
    rescue => e
      { status: :error, error: e.message }
    end
  end
end
