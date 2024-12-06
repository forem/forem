# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

require_relative '../../request'
require_relative '../../response'

module Vault
  class Transform < Request
    class Alphabet < Response
      # @!attribute [r] id
      #   String listing all possible characters of the alphabet
      #   @return [String]
      field :alphabet
    end

    def create_alphabet(name, alphabet:, **opts)
      opts ||= {}
      opts[:alphabet] = alphabet
      client.post("/v1/transform/alphabet/#{encode_path(name)}", JSON.fast_generate(opts))
      return true
    end

    def get_alphabet(name)
      json = client.get("/v1/transform/alphabet/#{encode_path(name)}")
      if data = json.dig(:data)
        Alphabet.decode(data)
      else
        json
      end
    end

    def delete_alphabet(name)
      client.delete("/v1/transform/alphabet/#{encode_path(name)}")
      true
    end

    def alphabets
      json = client.list("/v1/transform/alphabet")
      if keys = json.dig(:data, :keys)
        keys
      else
        json
      end
    end
  end
end
