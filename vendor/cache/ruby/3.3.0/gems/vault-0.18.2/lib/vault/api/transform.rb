# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

require_relative '../client'
require_relative '../request'

module Vault
  class Client
    # A proxy to the {Transform} methods.
    # @return [Transform]
    def transform
      @transform ||= Transform.new(self)
    end
  end

  class Transform < Request
    def encode(role_name:, **opts)
      opts ||= {}
      client.post("/v1/transform/encode/#{encode_path(role_name)}", JSON.fast_generate(opts))
    end

    def decode(role_name:, **opts)
      opts ||= {}
      client.post("/v1/transform/decode/#{encode_path(role_name)}", JSON.fast_generate(opts))
    end
  end
end

require_relative 'transform/alphabet'
require_relative 'transform/role'
require_relative 'transform/template'
require_relative 'transform/transformation'
