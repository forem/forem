# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

require "json"

module Vault
  class InitResponse < Response
    # @!attribute [r] keys
    #   List of unseal keys.
    #   @return [Array<String>]
    field :keys

    # @!attribute [r] keys_base64
    #   List of unseal keys, base64-encoded
    #   @return [Array<String>]
    field :keys_base64

    # @!attribute [r] root_token
    #   Initial root token.
    #   @return [String]
    field :root_token
  end

  class InitStatus < Response
    # @!method initialized?
    #   Returns whether the Vault server is initialized.
    #   @return [Boolean]
    field :initialized, as: :initialized?
  end

  class Sys
    # Show the initialization status for this vault.
    #
    # @example
    #   Vault.sys.init_status #=> #<Vault::InitStatus initialized=true>
    #
    # @return [InitStatus]
    def init_status
      json = client.get("/v1/sys/init")
      return InitStatus.decode(json)
    end

    # Initialize a new vault.
    #
    # @example
    #   Vault.sys.init #=> #<Vault::InitResponse keys=["..."] root_token="...">
    #
    # @param [Hash] options
    #   the list of init options
    #
    # @option options [String] :root_token_pgp_key
    #   optional base64-encoded PGP public key used to encrypt the initial root
    #   token.
    # @option options [Fixnum] :secret_shares
    #   the number of shares
    # @option options [Fixnum] :secret_threshold
    #   the number of keys needed to unlock
    # @option options [Array<String>] :pgp_keys
    #   an optional Array of base64-encoded PGP public keys to encrypt sharees
    # @option options [Fixnum] :stored_shares
    #   the number of shares that should be encrypted by the HSM for
    #   auto-unsealing
    # @option options [Fixnum] :recovery_shares
    #   the number of shares to split the recovery key into
    # @option options [Fixnum] :recovery_threshold
    #   the number of shares required to reconstruct the recovery key
    # @option options [Array<String>] :recovery_pgp_keys
    #   an array of PGP public keys used to encrypt the output for the recovery
    #   keys
    #
    # @return [InitResponse]
    def init(options = {})
      json = client.put("/v1/sys/init", JSON.fast_generate(
        root_token_pgp_key: options.fetch(:root_token_pgp_key, nil),
        secret_shares:      options.fetch(:secret_shares, options.fetch(:shares, 5)),
        secret_threshold:   options.fetch(:secret_threshold, options.fetch(:threshold, 3)),
        pgp_keys:           options.fetch(:pgp_keys, nil),
        stored_shares:      options.fetch(:stored_shares, nil),
        recovery_shares:    options.fetch(:recovery_shares, nil),
        recovery_threshold: options.fetch(:recovery_threshold, nil),
        recovery_pgp_keys:  options.fetch(:recovery_pgp_keys, nil),
      ))
      return InitResponse.decode(json)
    end
  end
end
