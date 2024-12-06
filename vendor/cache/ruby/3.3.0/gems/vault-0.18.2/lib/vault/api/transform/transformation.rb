# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

require_relative '../../request'
require_relative '../../response'

module Vault
  class Transform < Request
    class Transformation < Response
      # @!attribute [r] allowed_roles
      #   Array of role names that are allowed to use this transformation
      #   @return [Array<String>]
      field :allowed_roles

      # @!attribute [r] templates
      #   Array of template names accessible to this transformation
      #   @return [Array<String>]
      field :templates

      # @!attribute [r] tweak_source
      #   String representing how a tweak is provided for this transformation.
      #   Available tweaks are "supplied", "generated", and "internal"
      #   @return [String]
      field :tweak_source

      # @!attribute [r] type
      #   String representing the type of transformation this is.
      #   Available types are "fpe", and "masking"
      #   @return [String]
      field :type
    end

    def create_transformation(name, type:, template:, **opts)
      opts ||= {}
      opts[:type] = type
      opts[:template] = template
      client.post("/v1/transform/transformation/#{encode_path(name)}", JSON.fast_generate(opts))
      return true
    end

    def get_transformation(name)
      json = client.get("/v1/transform/transformation/#{encode_path(name)}")
      if data = json.dig(:data)
        Transformation.decode(data)
      else
        json
      end
    end

    def delete_transformation(name)
      client.delete("/v1/transform/transformation/#{encode_path(name)}")
      true
    end

    def transformations
      json = client.list("/v1/transform/transformation")
      if keys = json.dig(:data, :keys)
        keys
      else
        json
      end
    end
  end
end
