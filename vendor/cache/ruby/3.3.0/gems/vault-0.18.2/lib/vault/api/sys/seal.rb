# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

require "json"

module Vault
  class SealStatus < Response
    # @!method sealed?
    #   Returns if the Vault is sealed.
    #
    #   @example Check if the Vault is sealed
    #     status.sealed? #=> true
    #
    #   @return [Boolean]
    field :sealed, as: :sealed?

    # @!attribute t
    #   Threshold of keys required to unseal the Vault.
    #
    #   @example Get the threshold of keys
    #     status.t #=> 3
    #
    #   @return [Fixnum]
    field :t

    # @!attribute n
    #   Total number of unseal keys.
    #
    #   @example Get the total number of keys
    #     status.n #=> 5
    #
    #   @return [Fixnum]
    field :n

    # @!attribute progress
    #   Number of keys that have been entered.
    #
    #   @example Get the current unseal progress
    #     status.progress #=> 2
    #
    #   @return [Fixnum]
    field :progress
  end

  class Sys
    # Get the current seal status.
    #
    # @example
    #   Vault.sys.seal_status #=> #<Vault::SealStatus sealed=false, t=1, n=1, progress=0>
    #
    # @return [SealStatus]
    def seal_status
      json = client.get("/v1/sys/seal-status")
      return SealStatus.decode(json)
    end

    # Seal the vault. Warning: this will seal the vault!
    #
    # @example
    #   Vault.sys.seal #=> true
    #
    # @return [true]
    def seal
      client.put("/v1/sys/seal", nil)
      return true
    end

    # Unseal the vault with the given shard.
    #
    # @example
    #   Vault.sys.unseal("abcd-1234") #=> #<Vault::SealStatus sealed=true, t=3, n=5, progress=1>
    #
    # @param [String] shard
    #   the key to use
    #
    # @return [SealStatus]
    def unseal(shard)
      json = client.put("/v1/sys/unseal", JSON.fast_generate(
        key: shard,
      ))
      return SealStatus.decode(json)
    end
  end
end
