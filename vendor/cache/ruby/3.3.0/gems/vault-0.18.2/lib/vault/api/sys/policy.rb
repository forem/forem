# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

require "json"

module Vault
  class Policy < Response
    # @!attribute [r] name
    #   Name of the policy.
    #
    #   @example Get the name of the policy
    #     policy.name #=> "default"
    #
    #   @return [String]
    field :name

    # @!attribute [r] rules
    #   Raw HCL policy.
    #
    #   @example Display the list of rules
    #     policy.rules #=> "path \"secret/foo\" {}"
    #
    #   @return [String]
    field :rules
  end

  class Sys
    # The list of policies in vault.
    #
    # @example
    #   Vault.sys.policies #=> ["root"]
    #
    # @return [Array<String>]
    def policies
      client.get("/v1/sys/policy")[:policies]
    end

    # Get the policy by the given name. If a policy does not exist by that name,
    # +nil+ is returned.
    #
    # @example
    #   Vault.sys.policy("root") #=> #<Vault::Policy rules="">
    #
    # @return [Policy, nil]
    def policy(name)
      json = client.get("/v1/sys/policy/#{encode_path(name)}")
      return Policy.decode(json)
    rescue HTTPError => e
      return nil if e.code == 404
      raise
    end

    # Create a new policy with the given name and rules.
    #
    # @example
    #   policy = <<-EOH
    #     path "sys" {
    #       policy = "deny"
    #     }
    #   EOH
    #   Vault.sys.put_policy("dev", policy) #=> true
    #
    # It is recommend that you load policy rules from a file:
    #
    # @example
    #   policy = File.read("/path/to/my/policy.hcl")
    #   Vault.sys.put_policy("dev", policy)
    #
    # @param [String] name
    #   the name of the policy
    # @param [String] rules
    #   the policy rules
    #
    # @return [true]
    def put_policy(name, rules)
      client.put("/v1/sys/policy/#{encode_path(name)}", JSON.fast_generate(
        rules: rules,
      ))
      return true
    end

    # Delete the policy with the given name. If a policy does not exist, vault
    # will not return an error.
    #
    # @example
    #   Vault.sys.delete_policy("dev") #=> true
    #
    # @param [String] name
    #   the name of the policy
    def delete_policy(name)
      client.delete("/v1/sys/policy/#{encode_path(name)}")
      return true
    end
  end
end
