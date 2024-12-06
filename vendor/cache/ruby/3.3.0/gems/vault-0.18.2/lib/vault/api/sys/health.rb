# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

require "json"

module Vault
  class HealthStatus < Response
    # @!attribute [r] initialized
    #   Whether the Vault server is Initialized.
    #   @return [Boolean]
    field :initialized, as: :initialized?

    # @!attribute [r] sealed
    #   Whether the Vault server is Sealed.
    #   @return [Boolean]
    field :sealed, as: :sealed?

    # @!attribute [r] standby
    #   Whether the Vault server is in Standby mode.
    #   @return [Boolean]
    field :standby, as: :standby?

    # @!attribute [r] replication_performance_mode
    #   Verbose description of DR mode (added in 0.9.2)
    #   @return [String]
    field :replication_performance_mode

    # @!attribute [r] replication_dr_mode
    #   Verbose description of DR mode (added in 0.9.2)
    #   @return [String]
    field :replication_dr_mode

    # @!attribute [r] server_time_utc
    #   Server time in Unix seconds, UTC
    #   @return [Fixnum]
    field :server_time_utc

    # @!attribute [r] version
    #   Server Vault version string (added in 0.6.1)
    #   @return [String]
    field :version

    # @!attribute [r] cluster_name
    #   Server cluster name
    #   @return [String]
    field :cluster_name

    # @!attribute [r] cluster_id
    #   Server cluster UUID
    #   @return [String]
    field :cluster_id
  end

  class Sys
    # Show the health status for this vault.
    #
    # @example
    #   Vault.sys.health_status #=> #Vault::HealthStatus @initialized=true, @sealed=false, @standby=false, @replication_performance_mode="disabled", @replication_dr_mode="disabled", @server_time_utc=1519776728, @version="0.9.3", @cluster_name="vault-cluster-997f514e", @cluster_id="c2dad70a-6d88-a06d-69f6-9ae7f5485998">
    #
    # @return [HealthStatus]
    def health_status
      json = client.get("/v1/sys/health", {:sealedcode => 200, :uninitcode => 200, :standbycode => 200})
      return HealthStatus.decode(json)
    end
  end
end
