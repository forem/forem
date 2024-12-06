# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

require "json"

module Vault
  class Auth < Response
    # @!attribute [r] description
    #   Description of the auth backend.
    #   @return [String]
    field :description

    # @!attribute [r] type
    #   Name of the auth backend.
    #   @return [String]
    field :type
  end

  class AuthConfig < Response
    # @!attribute [r] default_lease_ttl
    #   The default time-to-live.
    #   @return [String]
    field :default_lease_ttl

    # @!attribute [r] max_lease_ttl
    #   The maximum time-to-live.
    #   @return [String]
    field :max_lease_ttl
  end

  class Sys
    # List all auths in Vault.
    #
    # @example
    #   Vault.sys.auths #=> {:token => #<Vault::Auth type="token", description="token based credentials">}
    #
    # @return [Hash<Symbol, Auth>]
    def auths
      json = client.get("/v1/sys/auth")
      json = json[:data] if json[:data]
      return Hash[*json.map do |k,v|
        [k.to_s.chomp("/").to_sym, Auth.decode(v)]
      end.flatten]
    end

    # Enable a particular authentication at the given path.
    #
    # @example
    #   Vault.sys.enable_auth("github", "github") #=> true
    #
    # @param [String] path
    #   the path to mount the auth
    # @param [String] type
    #   the type of authentication
    # @param [String] description
    #   a human-friendly description (optional)
    #
    # @return [true]
    def enable_auth(path, type, description = nil)
      payload = { type: type }
      payload[:description] = description if !description.nil?

      client.post("/v1/sys/auth/#{encode_path(path)}", JSON.fast_generate(payload))
      return true
    end

    # Disable a particular authentication at the given path. If not auth
    # exists at that path, an error will be raised.
    #
    # @example
    #   Vault.sys.disable_auth("github") #=> true
    #
    # @param [String] path
    #   the path to disable
    #
    # @return [true]
    def disable_auth(path)
      client.delete("/v1/sys/auth/#{encode_path(path)}")
      return true
    end

    # Read the given auth path's configuration.
    #
    # @example
    #   Vault.sys.auth_tune("github") #=> #<Vault::AuthConfig "default_lease_ttl"=3600, "max_lease_ttl"=7200>
    #
    # @param [String] path
    #   the path to retrieve configuration for
    #
    # @return [AuthConfig]
    #   configuration of the given auth path
    def auth_tune(path)
      json = client.get("/v1/sys/auth/#{encode_path(path)}/tune")
      return AuthConfig.decode(json)
    rescue HTTPError => e
      return nil if e.code == 404
      raise
    end

    # Write the given auth path's configuration.
    #
    # @example
    #   Vault.sys.auth_tune("github", "default_lease_ttl" => 600, "max_lease_ttl" => 1200 ) #=>  true
    #
    # @param [String] path
    #   the path to retrieve configuration for
    #
    # @return [AuthConfig]
    #   configuration of the given auth path
    def put_auth_tune(path, config = {})
      json = client.put("/v1/sys/auth/#{encode_path(path)}/tune", JSON.fast_generate(config))
      if json.nil?
        return true
      else
        return Secret.decode(json)
      end
    end
  end
end
