# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

require "json"

require_relative "secret"
require_relative "../client"
require_relative "../request"
require_relative "../response"

module Vault
  class Client
    # A proxy to the {AuthToken} methods.
    # @return [AuthToken]
    def auth_token
      @auth_token ||= AuthToken.new(self)
    end
  end

  class AuthToken < Request
    # Lists all token accessors.
    #
    # @example Listing token accessors
    #   result = Vault.auth_token.accessors #=> #<Vault::Secret>
    #   result.data[:keys] #=> ["476ea048-ded5-4d07-eeea-938c6b4e43ec", "bb00c093-b7d3-b0e9-69cc-c4d85081165b"]
    #
    # @return [Array<Secret>]
    def accessors(options = {})
      headers = extract_headers!(options)
      json = client.list("/v1/auth/token/accessors", options, headers)
      return Secret.decode(json)
    end

    # Create an authentication token. Note that the parameters specified below
    # are not validated and passed directly to the Vault server. Depending on
    # the version of Vault in operation, some of these options may not work, and
    # newer options may be available that are not listed here.
    #
    # @example Creating a token
    #   Vault.auth_token.create #=> #<Vault::Secret lease_id="">
    #
    # @example Creating a token assigned to policies with a wrap TTL
    #   Vault.auth_token.create(
    #     policies: ["myapp"],
    #     wrap_ttl: 500,
    #   )
    #
    # @param [Hash] options
    # @option options [String] :id
    #   The ID of the client token - this can only be specified for root tokens
    # @option options [Array<String>] :policies
    #   List of policies to apply to the token
    # @option options [Fixnum, String] :wrap_ttl
    #   The number of seconds or a golang-formatted timestamp like "5s" or "10m"
    #   for the TTL on the wrapped response
    # @option options [Hash<String, String>] :meta
    #   A map of metadata that is passed to audit backends
    # @option options [Boolean] :no_parent
    #   Create a token without a parent - see also {#create_orphan}
    # @option options [Boolean] :no_default_policy
    #   Create a token without the default policy attached
    # @option options [Boolean] :renewable
    #   Set whether this token is renewable or not
    # @option options [String] :display_name
    #   Name of the token
    # @option options [Fixnum] :num_uses
    #   Maximum number of uses for the token
    #
    # @return [Secret]
    def create(options = {})
      headers = extract_headers!(options)
      json = client.post("/v1/auth/token/create", JSON.fast_generate(options), headers)
      return Secret.decode(json)
    end

    # Create an orphaned authentication token.
    #
    # @example
    #   Vault.auth_token.create_orphan #=> #<Vault::Secret lease_id="">
    #
    # @param (see #create)
    # @option (see #create)
    #
    # @return [Secret]
    def create_orphan(options = {})
      headers = extract_headers!(options)
      json = client.post("/v1/auth/token/create-orphan", JSON.fast_generate(options), headers)
      return Secret.decode(json)
    end

    # Create an orphaned authentication token.
    #
    # @example
    #   Vault.auth_token.create_with_role("developer") #=> #<Vault::Secret lease_id="">
    #
    # @param [Hash] options
    #
    # @return [Secret]
    def create_with_role(name, options = {})
      headers = extract_headers!(options)
      json = client.post("/v1/auth/token/create/#{encode_path(name)}", JSON.fast_generate(options), headers)
      return Secret.decode(json)
    end

    # Lookup information about the current token.
    #
    # @example
    #   Vault.auth_token.lookup("abcd-...") #=> #<Vault::Secret lease_id="">
    #
    # @param [String] token
    # @param [Hash] options
    #
    # @return [Secret]
    def lookup(token, options = {})
      headers = extract_headers!(options)
      json = client.post("/v1/auth/token/lookup", JSON.fast_generate(
        token: token,
      ), headers)
      return Secret.decode(json)
    end

    # Lookup information about the given token accessor.
    #
    # @example
    #   Vault.auth_token.lookup_accessor("acbd-...") #=> #<Vault::Secret lease_id="">
    #
    # @param [String] accessor
    # @param [Hash] options
    def lookup_accessor(accessor, options = {})
      headers = extract_headers!(options)
      json = client.post("/v1/auth/token/lookup-accessor", JSON.fast_generate(
        accessor: accessor,
      ), headers)
      return Secret.decode(json)
    end

    # Lookup information about the given token.
    #
    # @example
    #   Vault.auth_token.lookup_self #=> #<Vault::Secret lease_id="">
    #
    # @return [Secret]
    def lookup_self
      json = client.get("/v1/auth/token/lookup-self")
      return Secret.decode(json)
    end

    # Renew the given authentication token.
    #
    # @example
    #   Vault.auth_token.renew("abcd-1234") #=> #<Vault::Secret lease_id="">
    #
    # @param [String] token
    #   the auth token
    # @param [Fixnum] increment
    #
    # @return [Secret]
    def renew(token, increment = 0, options = {})
      headers = extract_headers!(options)
      json = client.put("/v1/auth/token/renew", JSON.fast_generate(
        token: token,
        increment: increment,
      ), headers)
      return Secret.decode(json)
    end

    # Renews a lease associated with the calling token.
    #
    # @example
    #   Vault.auth_token.renew_self #=> #<Vault::Secret lease_id="">
    #
    # @param [Fixnum] increment
    #
    # @return [Secret]
    def renew_self(increment = 0, options = {})
      headers = extract_headers!(options)
      json = client.put("/v1/auth/token/renew-self", JSON.fast_generate(
        increment: increment,
      ), headers)
      return Secret.decode(json)
    end

    # Revokes the token used to call it.
    #
    # @example
    #   Vault.auth_token.revoke_self #=> 204
    #
    # @return response code.
    def revoke_self
      client.post("/v1/auth/token/revoke-self")
    end

    # Revoke exactly the orphans at the id.
    #
    # @example
    #   Vault.auth_token.revoke_orphan("abcd-1234") #=> true
    #
    # @param [String] token
    #   the token to revoke
    #
    # @return [true]
    def revoke_orphan(token, options = {})
      headers = extract_headers!(options)
      client.put("/v1/auth/token/revoke-orphan", JSON.fast_generate(
        token: token,
      ), headers)
      return true
    end

    # Revoke exactly the orphans at the id.
    #
    # @example
    #   Vault.auth_token.revoke_accessor("abcd-1234") #=> true
    #
    # @param [String] accessor
    #   the accessor to revoke
    #
    # @return [true]
    def revoke_accessor(accessor, options = {})
      headers = extract_headers!(options)
      client.put("/v1/auth/token/revoke-accessor", JSON.fast_generate(
        accessor: accessor,
      ), headers)
      return true
    end

    # Revoke the token and all its children.
    #
    # @example
    #   Vault.auth_token.revoke("abcd-1234") #=> true
    #
    # @param [String] token
    #   the auth token
    #
    # @return [true]
    def revoke(token, options = {})
      headers = extract_headers!(options)
      client.put("/v1/auth/token/revoke", JSON.fast_generate(
        token: token,
      ), headers)
      return true
    end
    alias_method :revoke_tree, :revoke
  end
end
