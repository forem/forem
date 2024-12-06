# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

module Vault
  class Sys
    # Renew a lease with the given ID.
    #
    # @example
    #   Vault.sys.renew("aws/username") #=> #<Vault::Secret ...>
    #
    # @param [String] id
    #   the lease ID
    # @param [Fixnum] increment
    #
    # @return [Secret]
    def renew(id, increment = 0)
      json = client.put("/v1/sys/renew/#{id}", JSON.fast_generate(
        increment: increment,
      ))
      return Secret.decode(json)
    end

    # Revoke the secret at the given id. If the secret does not exist, an error
    # will be raised.
    #
    # @example
    #   Vault.sys.revoke("aws/username") #=> true
    #
    # @param [String] id
    #   the lease ID
    #
    # @return [true]
    def revoke(id)
      client.put("/v1/sys/revoke/#{id}", nil)
      return true
    end

    # Revoke all secrets under the given prefix.
    #
    # @example
    #   Vault.sys.revoke_prefix("aws") #=> true
    #
    # @param [String] id
    #   the lease ID
    #
    # @return [true]
    def revoke_prefix(id)
      client.put("/v1/sys/revoke-prefix/#{id}", nil)
      return true
    end
  end
end
