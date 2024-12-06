# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

require "json"

require_relative "secret"
require_relative "../client"
require_relative "../request"
require_relative "../response"

module Vault
  class Client
    # A proxy to the {AppRole} methods.
    # @return [AppRole]
    def approle
      @approle ||= AppRole.new(self)
    end
  end

  class AppRole < Request
    # Creates a new AppRole or update an existing AppRole with the given name
    # and attributes.
    #
    # @example
    #   Vault.approle.set_role("testrole", {
    #     secret_id_ttl: "10m",
    #     token_ttl:     "20m",
    #     policies:      "default",
    #     period:        3600,
    #   }) #=> true
    #
    # @param [String] name
    #   The name of the AppRole
    # @param [Hash] options
    # @option options [Boolean] :bind_secret_id
    #   Require secret_id to be presented when logging in using this AppRole.
    # @option options [String] :bound_cidr_list
    #   Comma-separated list of CIDR blocks. Specifies blocks of IP addresses
    #   which can perform the login operation.
    # @option options [String] :policies
    #   Comma-separated list of policies set on tokens issued via this AppRole.
    # @option options [String] :secret_id_num_uses
    #   Number of times any particular SecretID can be used to fetch a token
    #   from this AppRole, after which the SecretID will expire.
    # @option options [Fixnum, String] :secret_id_ttl
    #   The number of seconds or a golang-formatted timestamp like "60m" after
    #   which any SecretID expires.
    # @option options [Fixnum, String] :token_ttl
    #   The number of seconds or a golang-formatted timestamp like "60m" to set
    #   as the TTL for issued tokens and at renewal time.
    # @option options [Fixnum, String] :token_max_ttl
    #   The number of seconds or a golang-formatted timestamp like "60m" after
    #   which the issued token can no longer be renewed.
    # @option options [Fixnum, String] :period
    #   The number of seconds or a golang-formatted timestamp like "60m".
    #   If set, the token generated using this AppRole is a periodic token.
    #   So long as it is renewed it never expires, but the TTL set on the token
    #   at each renewal is fixed to the value specified here. If this value is
    #   modified, the token will pick up the new value at its next renewal.
    #
    # @return [true]
    def set_role(name, options = {})
      headers = extract_headers!(options)
      client.post("/v1/auth/approle/role/#{encode_path(name)}", JSON.fast_generate(options), headers)
      return true
    end

    # Gets the AppRole by the given name. If an AppRole does not exist by that
    # name, +nil+ is returned.
    #
    # @example
    #   Vault.approle.role("testrole") #=> #<Vault::Secret lease_id="...">
    #
    # @return [Secret, nil]
    def role(name)
      json = client.get("/v1/auth/approle/role/#{encode_path(name)}")
      return Secret.decode(json)
    rescue HTTPError => e
      return nil if e.code == 404
      raise
    end

    # Gets the list of AppRoles in vault auth backend.
    #
    # @example
    #   Vault.approle.roles #=> ["testrole"]
    #
    # @return [Array<String>]
    def roles(options = {})
      headers = extract_headers!(options)
      json = client.list("/v1/auth/approle/role", options, headers)
      return Secret.decode(json).data[:keys] || []
    rescue HTTPError => e
      return [] if e.code == 404
      raise
    end

    # Reads the RoleID of an existing AppRole. If an AppRole does not exist by
    # that name, +nil+ is returned.
    #
    # @example
    #   Vault.approle.role_id("testrole") #=> #<Vault::Secret lease_id="...">
    #
    # @return [Secret, nil]
    def role_id(name)
      json = client.get("/v1/auth/approle/role/#{encode_path(name)}/role-id")
      return Secret.decode(json).data[:role_id]
    rescue HTTPError => e
      return nil if e.code == 404
      raise
    end

    # Updates the RoleID of an existing AppRole to a custom value.
    #
    # @example
    #   Vault.approle.set_role_id("testrole") #=> true
    #
    # @return [true]
    def set_role_id(name, role_id)
      options = { role_id: role_id }
      client.post("/v1/auth/approle/role/#{encode_path(name)}/role-id", JSON.fast_generate(options))
      return true
    end

    # Deletes the AppRole with the given name. If an AppRole does not exist,
    # vault will not return an error.
    #
    # @example
    #   Vault.approle.delete_role("testrole") #=> true
    #
    # @param [String] name
    #   the name of the certificate
    def delete_role(name)
      client.delete("/v1/auth/approle/role/#{encode_path(name)}")
      return true
    end

    # Generates and issues a new SecretID on an existing AppRole.
    #
    # @example Generate a new SecretID
    #   result = Vault.approle.create_secret_id("testrole") #=> #<Vault::Secret lease_id="...">
    #   result.data[:secret_id] #=> "841771dc-11c9-bbc7-bcac-6a3945a69cd9"
    #
    # @example Assign a custom SecretID
    #   result = Vault.approle.create_secret_id("testrole", {
    #     secret_id: "testsecretid"
    #   }) #=> #<Vault::Secret lease_id="...">
    #   result.data[:secret_id] #=> "testsecretid"
    #
    # @param [String] role_name
    #   The name of the AppRole
    # @param [Hash] options
    # @option options [String] :secret_id
    #   SecretID to be attached to the Role. If not set, then the new SecretID
    #   will be generated
    # @option options [Hash<String, String>] :metadata
    #   Metadata to be tied to the SecretID. This should be a JSON-formatted
    #   string containing the metadata in key-value pairs. It will be set on
    #   tokens issued with this SecretID, and is logged in audit logs in
    #   plaintext.
    #
    # @return [true]
    def create_secret_id(role_name, options = {})
      headers = extract_headers!(options)
      if options[:secret_id]
        json = client.post("/v1/auth/approle/role/#{encode_path(role_name)}/custom-secret-id", JSON.fast_generate(options), headers)
      else
        json = client.post("/v1/auth/approle/role/#{encode_path(role_name)}/secret-id", JSON.fast_generate(options), headers)
      end
      return Secret.decode(json)
    end

    # Reads out the properties of a SecretID assigned to an AppRole.
    # If the specified SecretID don't exist, +nil+ is returned.
    #
    # @example
    #   Vault.approle.role("testrole", "841771dc-11c9-...") #=> #<Vault::Secret lease_id="...">
    #
    # @param [String] role_name
    #   The name of the AppRole
    # @param [String] secret_id
    #   SecretID belonging to AppRole
    #
    # @return [Secret, nil]
    def secret_id(role_name, secret_id)
      opts = { secret_id: secret_id }
      json = client.post("/v1/auth/approle/role/#{encode_path(role_name)}/secret-id/lookup", JSON.fast_generate(opts), {})
      return nil unless json
      return Secret.decode(json)
    rescue HTTPError => e
      if e.code == 404 || e.code == 405
        begin
          json = client.get("/v1/auth/approle/role/#{encode_path(role_name)}/secret-id/#{encode_path(secret_id)}")
          return Secret.decode(json)
        rescue HTTPError => e
          return nil if e.code == 404
          raise e
        end
      end

      raise
    end

    # Lists the accessors of all the SecretIDs issued against the AppRole.
    # This includes the accessors for "custom" SecretIDs as well. If there are
    # no SecretIDs against this role, an empty array will be returned.
    #
    # @example
    #   Vault.approle.secret_ids("testrole") #=> ["ce102d2a-...", "a1c8dee4-..."]
    #
    # @return [Array<String>]
    def secret_id_accessors(role_name, options = {})
      headers = extract_headers!(options)
      json = client.list("/v1/auth/approle/role/#{encode_path(role_name)}/secret-id", options, headers)
      return Secret.decode(json).data[:keys] || []
    rescue HTTPError => e
      return [] if e.code == 404
      raise
    end
  end
end
