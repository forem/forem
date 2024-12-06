# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

require_relative '../../request'
require_relative '../../response'

module Vault
  class Transform < Request
    class Role < Response
      # @!attribute [r] transformations
      #   Array of all transformations the role has access to
      #   @return [Array<String>]
      field :transformations
    end

    def create_role(name, **opts)
      opts ||= {}
      client.post("/v1/transform/role/#{encode_path(name)}", JSON.fast_generate(opts))
      return true
    end

    def get_role(name)
      json = client.get("/v1/transform/role/#{encode_path(name)}")
      if data = json.dig(:data)
        Role.decode(data)
      else
        json
      end
    end

    def delete_role(name)
      client.delete("/v1/transform/role/#{encode_path(name)}")
      true
    end

    def roles
      json = client.list("/v1/transform/role")
      if keys = json.dig(:data, :keys)
        keys
      else
        json
      end
    end
  end
end
