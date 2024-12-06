# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

require_relative "secret"
require_relative "../client"
require_relative "../request"
require_relative "../response"

module Vault
  class Client
    # A proxy to the {Logical} methods.
    # @return [Logical]
    def logical
      @logical ||= Logical.new(self)
    end
  end

  class Logical < Request
    # List the secrets at the given path, if the path supports listing. If the
    # the path does not exist, an exception will be raised.
    #
    # @example
    #   Vault.logical.list("secret") #=> [#<Vault::Secret>, #<Vault::Secret>, ...]
    #
    # @param [String] path
    #   the path to list
    #
    # @return [Array<String>]
    def list(path, options = {})
      headers = extract_headers!(options)
      json = client.list("/v1/#{encode_path(path)}", {}, headers)
      json[:data][:keys] || []
    rescue HTTPError => e
      return [] if e.code == 404
      raise
    end

    # Read the secret at the given path. If the secret does not exist, +nil+
    # will be returned.
    #
    # @example
    #   Vault.logical.read("secret/password") #=> #<Vault::Secret lease_id="">
    #
    # @param [String] path
    #   the path to read
    #
    # @return [Secret, nil]
    def read(path, options = {})
      headers = extract_headers!(options)
      json = client.get("/v1/#{encode_path(path)}", {}, headers)
      return Secret.decode(json)
    rescue HTTPError => e
      return nil if e.code == 404
      raise
    end

    # Write the secret at the given path with the given data. Note that the
    # data must be a {Hash}!
    #
    # @example
    #   Vault.logical.write("secret/password", value: "secret") #=> #<Vault::Secret lease_id="">
    #
    # @param [String] path
    #   the path to write
    # @param [Hash] data
    #   the data to write
    #
    # @return [Secret]
    def write(path, data = {}, options = {})
      headers = extract_headers!(options)
      json = client.put("/v1/#{encode_path(path)}", JSON.fast_generate(data), headers)
      if json.nil?
        return true
      else
        return Secret.decode(json)
      end
    end

    # Delete the secret at the given path. If the secret does not exist, vault
    # will still return true.
    #
    # @example
    #   Vault.logical.delete("secret/password") #=> true
    #
    # @param [String] path
    #   the path to delete
    #
    # @return [true]
    def delete(path)
      client.delete("/v1/#{encode_path(path)}")
      return true
    end

    # Unwrap the data stored against the given token. If the secret does not
    # exist, `nil` will be returned.
    #
    # @example
    #   Vault.logical.unwrap("f363dba8-25a7-08c5-430c-00b2367124e6") #=> #<Vault::Secret lease_id="">
    #
    # @param [String] wrapper
    #   the token to use when unwrapping the value
    #
    # @return [Secret, nil]
    def unwrap(wrapper)
      client.with_token(wrapper) do |client|
        json = client.get("/v1/cubbyhole/response")
        secret = Secret.decode(json)

        # If there is nothing in the cubbyhole, return early.
        if secret.nil? || secret.data.nil? || secret.data[:response].nil?
          return nil
        end

        # Extract the response and parse it into a new secret.
        json = JSON.parse(secret.data[:response], symbolize_names: true)
        secret = Secret.decode(json)
        return secret
      end
    rescue HTTPError => e
      return nil if e.code == 404
      raise
    end

    # Unwrap a token in a wrapped response given the temporary token.
    #
    # @example
    #   Vault.logical.unwrap("f363dba8-25a7-08c5-430c-00b2367124e6") #=> "0f0f40fd-06ce-4af1-61cb-cdc12796f42b"
    #
    # @param [String, Secret] wrapper
    #   the token to unwrap
    #
    # @return [String, nil]
    def unwrap_token(wrapper)
      # If provided a secret, grab the token. This is really just to make the
      # API a bit nicer.
      if wrapper.is_a?(Secret)
        wrapper = wrapper.wrap_info.token
      end

      # Unwrap
      response = unwrap(wrapper)

      # If nothing was there, return nil
      if response.nil? || response.auth.nil?
        return nil
      end

      return response.auth.client_token
    rescue HTTPError => e
      raise
    end
  end
end
