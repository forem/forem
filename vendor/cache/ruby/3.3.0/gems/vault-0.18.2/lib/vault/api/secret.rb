# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

require "time"

require_relative "../response"

module Vault
  # Secret is a representation of a secret from Vault. Almost all data returned
  # from Vault is represented as a secret.
  class Secret < Response
    # @!attribute [r] auth
    #   Authentication information for this secret, if any. Most secrets will
    #   contain this field, but it may also be `nil`. When authenticating to
    #   Vault, the resulting Vault token will be included in this embedded
    #   field.
    #
    #   @example Authenticating to Vault
    #     secret = Vault.auth.userpass("username", "password")
    #     secret.auth.client_token #=> "fdb29070-6379-70c9-ca3a-46152fb66de1"
    #
    #   @return [SecretAuth, nil]
    field :auth, load: ->(v) { SecretAuth.decode(v) }

    # @!attribute [r] data
    #   Arbitrary data returned by the secret. The keys returned are dependent
    #   upon the request made. For more information on the names of the keys
    #   that may be returned, please see the Vault documentation.
    #
    #   @example Reading data
    #     secret = Vault.auth.token("abcd1234")
    #     secret.data[:id] #=> "abcd1234"
    #     secret.data[:ttl] #=> 0
    #
    #   @return [Hash<Symbol, Object>]
    field :data, freeze: true

    # @!attribute [r] metadata
    #   Read-only metadata information related to the secret.
    #
    #   @example Reading metadata
    #     secret = Vault.logical(:versioned).read("secret", "foo")
    #     secret.metadata[:created_time] #=> "2018-12-08T04:22:54.168065Z"
    #     secret.metadata[:version]      #=> 1
    #     secret.metadata[:destroyed]    #=> false
    #
    #   @return [Hash<Symbol, Object>]
    field :metadata, freeze: true

    # @!attribute [r] lease_duration
    #   The number of seconds this lease is valid. If this number is 0 or nil,
    #   the secret does not expire.
    #
    #   @example Getting lease duration
    #     secret = Vault.logical.read("secret/foo")
    #     secret.lease_duration #=> 2592000 # 30 days
    #
    #   @return [Fixnum]
    field :lease_duration

    # @!attribute [r] lease_id
    #   Unique ID for the lease associated with this secret. The `lease_id` is a
    #   path and UUID that uniquely represents the secret. This may be used for
    #   renewing and revoking the secret, if permitted.
    #
    #   @example Getting lease ID
    #     secret = Vault.logical.read("postgresql/creds/readonly")
    #     secret.lease_id #=> "postgresql/readonly/fdb29070-6379-70c9-ca3a-46152fb66de1"
    #
    #   @return [String]
    field :lease_id

    # @!method [r] renewable?
    #   Returns whether this lease is renewable.
    #
    #   @example Checking if a lease is renewable
    #     secret = Vault.logical.read("secret/foo")
    #     secret.renewable? #=> false
    #
    #   @return [Boolean]
    field :renewable, as: :renewable?

    # @!attribute [r] warnings
    #   List of warnings returned by the Vault server. These are returned by the
    #   Vault server and may include deprecation information, new APIs, or
    #   request using the API differently in the future.
    #
    #   @example Display warnings
    #     result = Vault.logical.read("secret/foo")
    #     result.warnings #=> ["This path has been deprecated"]
    #
    #   @return [Array<String>, nil]
    field :warnings, freeze: true

    # @!attribute [r] wrap_info
    #   Wrapped information sent with the request (only present in Vault 0.6+).
    #   @return [WrapInfo, nil]
    field :wrap_info, load: ->(v) { WrapInfo.decode(v) }
  end

  # SecretAuth is a struct that contains the information about auth data, if
  # present. This is never returned alone and is usually embededded in a
  # {Secret}.
  class SecretAuth < Response
    # @!attribute [r] accessor
    #   Accessor for the token. This is like a `lease_id`, but for a token.
    #   @return [String]
    field :accessor

    # @!attribute [r] client_token
    #   The client token for this authentication.
    #   @return [String]
    field :client_token

    # @!attribute [r] lease_duration
    #   Number of seconds the token is valid.
    #   @return [Fixnum]
    field :lease_duration

    # @!attribute [r] metadata
    #   Arbitrary metadata from the authentication.
    #
    #   @example Listing metadata attached to an authentication
    #     auth.metadata #=> { :username => "sethvargo" }
    #
    #   @return [Hash<Symbol, Object>, nil]
    field :metadata, freeze: true

    # @!attribute [r] policies
    #   List of policies attached to this authentication.
    #
    #   @example Listing policies attached to an authentication
    #     auth.policies #=> ["default"]
    #
    #   @return [Array<String>, nil]
    field :policies, freeze: true

    # @!attribute [r] renewable
    #   Returns whether this authentication is renewable.
    #
    #   @example Checking if an authentication is renewable
    #     auth.renewable? #=> false
    #
    #   @return [Boolean]
    field :renewable, as: :renewable?
  end

  # WrapInfo is the information returned by a wrapped response. This is almost
  # always embedded as part of a {Secret}.
  class WrapInfo < Response
    # @!attribute [r] token
    #   Wrapped response token. This token may be used to unwrap the response.
    #   @return [String]
    field :token

    # @!attribute [r] wrapped_accessor
    #   Accessor for the wrapped token. This is like a `lease_id`, but for a token.
    #   @return [String]
    field :wrapped_accessor

    # @!attribute [r] creation_time
    #   Date & time when the wrapped token was created
    #   @return [Time]
    field :creation_time, load: ->(v) { Time.parse(v) }

    # @!attribute [r] ttl
    #   The TTL on the token returned in seconds.
    #   @return [Fixnum]
    field :ttl
  end
end
