# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

require "json"

require_relative "secret"
require_relative "../client"
require_relative "../request"
require_relative "../response"

module Vault
  class Client
    # A proxy to the {AuthTLS} methods.
    # @return [AuthTLS]
    def auth_tls
      @auth_tls ||= AuthTLS.new(self)
    end
  end

  class AuthTLS < Request
    # Saves a certificate with the given name and attributes. The certificate
    # with the given name must already exist.
    #
    # @example
    #   Vault.auth_tls.set_certificate("web", {
    #     display_name: "web-cert",
    #     certificate:  "-----BEGIN CERTIFICATE...",
    #     policies:     "default",
    #     ttl:          3600,
    #   }) #=> true
    #
    # @param [String] name
    #   the name of the certificate
    # @param [Hash] options
    # @option options [String] :certificate
    #   The PEM-formatted CA certificate.
    # @option options [String] :policies
    #   A comma-separated list of policies issued when authenticating with this
    #   CA.
    # @option options [String] :display_name
    #   The name to display on tokens issued against this CA.
    # @option options [Fixnum] :ttl
    #   The TTL period of the token, provided as a number of seconds.
    #
    # @return [true]
    def set_certificate(name, options = {})
      headers = extract_headers!(options)
      client.post("/v1/auth/cert/certs/#{encode_path(name)}", JSON.fast_generate(options), headers)
      return true
    end

    # Get the certificate by the given name. If a certificate does not exist by that name,
    # +nil+ is returned.
    #
    # @example
    #   Vault.auth_tls.certificate("web") #=> #<Vault::Secret lease_id="...">
    #
    # @return [Secret, nil]
    def certificate(name)
      json = client.get("/v1/auth/cert/certs/#{encode_path(name)}")
      return Secret.decode(json)
    rescue HTTPError => e
      return nil if e.code == 404
      raise
    end

    # The list of certificates in vault auth backend.
    #
    # @example
    #   Vault.auth_tls.certificates #=> ["web"]
    #
    # @return [Array<String>]
    def certificates(options = {})
      headers = extract_headers!(options)
      json = client.list("/v1/auth/cert/certs", options, headers)
      return Secret.decode(json).data[:keys] || []
    rescue HTTPError => e
      return [] if e.code == 404
      raise
    end

    # Delete the certificate with the given name. If a certificate does not exist, vault
    # will not return an error.
    #
    # @example
    #   Vault.auth_tls.delete_certificate("web") #=> true
    #
    # @param [String] name
    #   the name of the certificate
    def delete_certificate(name)
      client.delete("/v1/auth/cert/certs/#{encode_path(name)}")
      return true
    end
  end
end
