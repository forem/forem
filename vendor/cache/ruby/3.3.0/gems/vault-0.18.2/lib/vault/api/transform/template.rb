# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

require_relative '../../request'
require_relative '../../response'

module Vault
  class Transform < Request
    class Template < Response
      # @!attribute [r] alphabet
      #   Name of the alphabet to be used in the template
      #   @return [String]
      field :alphabet

      # @!attribute [r] pattern
      #   Regex string to detect and match for the template
      #   @return [String]
      field :pattern

      # @!attribute [r] type
      #   Type of the template, currently, only "regex" is supported
      #   @return [String]
      field :type
    end

    def create_template(name, type:, pattern:, **opts)
      opts ||= {}
      opts[:type] = type
      opts[:pattern] = pattern
      client.post("/v1/transform/template/#{encode_path(name)}", JSON.fast_generate(opts))
      return true
    end

    def get_template(name)
      json = client.get("/v1/transform/template/#{encode_path(name)}")
      if data = json.dig(:data)
        Template.decode(data)
      else
        json
      end
    end

    def delete_template(name)
      client.delete("/v1/transform/template/#{encode_path(name)}")
      true
    end

    def templates
      json = client.list("/v1/transform/template")
      if keys = json.dig(:data, :keys)
        keys
      else
        json
      end
    end
  end
end
