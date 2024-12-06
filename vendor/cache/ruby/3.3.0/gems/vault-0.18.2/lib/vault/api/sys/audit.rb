# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

require "json"

module Vault
  class Audit < Response
    # @!attribute [r] description
    #   Description of the audit backend.
    #   @return [String]
    field :description

    # @!attribute [r] options
    #   Map of options configured to the audit backend.
    #   @return [Hash<Symbol, Object>]
    field :options

    # @!attribute [r] type
    #   Name of the audit backend.
    #   @return [String]
    field :type
  end

  class Sys
    # List all audits for the vault.
    #
    # @example
    #   Vault.sys.audits #=> { :file => #<Audit> }
    #
    # @return [Hash<Symbol, Audit>]
    def audits
      json = client.get("/v1/sys/audit")
      json = json[:data] if json[:data]
      return Hash[*json.map do |k,v|
        [k.to_s.chomp("/").to_sym, Audit.decode(v)]
      end.flatten]
    end

    # Enable a particular audit. Note: the +options+ depend heavily on the
    # type of audit being enabled. Please refer to audit-specific documentation
    # for which need to be enabled.
    #
    # @example
    #   Vault.sys.enable_audit("/file-audit", "file", "File audit", path: "/path/on/disk") #=> true
    #
    # @param [String] path
    #   the path to mount the audit
    # @param [String] type
    #   the type of audit to enable
    # @param [String] description
    #   a human-friendly description of the audit backend
    # @param [Hash] options
    #   audit-specific options
    #
    # @return [true]
    def enable_audit(path, type, description, options = {})
      client.put("/v1/sys/audit/#{encode_path(path)}", JSON.fast_generate(
        type:        type,
        description: description,
        options:     options,
      ))
      return true
    end

    # Disable a particular audit. If an audit does not exist, and error will be
    # raised.
    #
    # @param [String] path
    #   the path of the audit to disable
    #
    # @return [true]
    def disable_audit(path)
      client.delete("/v1/sys/audit/#{encode_path(path)}")
      return true
    end

    # Generates a HMAC verifier for a given input.
    #
    # @example
    #   Vault.sys.audit_hash("file-audit", "my input") #=> "hmac-sha256:30aa7de18a5e90bbc1063db91e7c387b32b9fa895977eb8c177bbc91e7d7c542"
    #
    # @param [String] path
    #   the path of the audit backend
    # @param [String] input
    #   the input to generate a HMAC for
    #
    # @return [String]
    def audit_hash(path, input)
      json = client.post("/v1/sys/audit-hash/#{encode_path(path)}", JSON.fast_generate(input: input))
      json = json[:data] if json[:data]
      json[:hash]
    end
  end
end
