# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

module Vault
  class LeaderStatus < Response
    # @!method ha_enabled?
    #   Returns whether the high-availability mode is enabled.
    #   @return [Boolean]
    field :ha_enabled, as: :ha_enabled?

    # @!method leader?
    #   Returns whether the Vault server queried is the leader.
    #   @return [Boolean]
    field :is_self, as: :leader?

    # @!attribute [r] address
    #   URL where the server is running.
    #   @return [String]
    field :leader_address, as: :address

    # @deprecated Use {#ha_enabled?} instead
    def ha?; ha_enabled?; end

    # @deprecated Use {#leader?} instead
    def is_leader?; leader?; end

    # @deprecated Use {#leader?} instead
    def is_self?; leader?; end

    # @deprecated Use {#leader?} instead
    def self?; leader?; end
  end

  class Sys
    # Determine the leader status for this vault.
    #
    # @example
    #   Vault.sys.leader #=> #<Vault::LeaderStatus ha_enabled=false, is_self=false, leader_address="">
    #
    # @return [LeaderStatus]
    def leader
      json = client.get("/v1/sys/leader")
      return LeaderStatus.decode(json)
    end

    def step_down
      client.put("/v1/sys/step-down", nil)
      return true
    end
  end
end
