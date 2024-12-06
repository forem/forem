# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

require_relative "secret"
require_relative "../client"
require_relative "../request"
require_relative "../response"

module Vault
  class Client
    # A proxy to the {KV} methods.
    # @return [KV]
    def kv(mount)
      KV.new(self, mount)
    end
  end

  class KV < Request
    attr_reader :mount

    def initialize(client, mount)
      super client

      @mount = mount
    end

    # List the names of secrets at the given path, if the path supports
    # listing. If the the path does not exist, an empty array will be returned.
    #
    # @example
    #   Vault.kv("secret").list("foo") #=> ["bar", "baz"]
    #
    # @param [String] path
    #   the path to list
    #
    # @return [Array<String>]
    def list(path = "", options = {})
      headers = extract_headers!(options)
      json = client.list("/v1/#{mount}/metadata/#{encode_path(path)}", {}, headers)
      json[:data][:keys] || []
    rescue HTTPError => e
      return [] if e.code == 404
      raise
    end

    # Read the secret at the given path. If the secret does not exist, +nil+
    # will be returned. The latest version is returned by default, but you
    # can request a specific version.
    #
    # @example
    #   Vault.kv("secret").read("password") #=> #<Vault::Secret lease_id="">
    #
    # @param [String] path
    #   the path to read
    # @param [Integer] version
    #   the version of the secret
    #
    # @return [Secret, nil]
    def read(path, version = nil, options = {})
      headers = extract_headers!(options)
      params  = {}
      params[:version] = version unless version.nil?

      json = client.get("/v1/#{mount}/data/#{encode_path(path)}", params, headers)
      return Secret.decode(json[:data])
    rescue HTTPError => e
      return nil if e.code == 404
      raise
    end

    # Read the metadata of a secret at the given path. If the secret does not
    # exist, nil will be returned.
    #
    # @example
    #    Vault.kv("secret").read_metadata("password") => {...}
    #
    # @param [String] path
    #   the path to read
    #
    # @return [Hash, nil]
    def read_metadata(path)
      client.get("/v1/#{mount}/metadata/#{encode_path(path)}")[:data]
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
      json = client.post("/v1/#{mount}/data/#{encode_path(path)}", JSON.fast_generate(:data => data), headers)
      if json.nil?
        return true
      else
        return Secret.decode(json)
      end
    end

    # Write the metadata of a secret at the given path. Note that the data must
    # be a {Hash}.
    #
    # @example
    #    Vault.kv("secret").write_metadata("password", max_versions => 3)
    #
    # @param [String] path
    #   the path to write
    # @param [Hash] metadata
    #    the metadata to write
    #
    # @return [true]
    def write_metadata(path, metadata = {})
      client.post("/v1/#{mount}/metadata/#{encode_path(path)}", JSON.fast_generate(metadata))

      true
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
      client.delete("/v1/#{mount}/data/#{encode_path(path)}")

      true
    end

    # Mark specific versions of a secret as deleted.
    #
    # @example
    #   Vault.kv("secret").delete_versions("password", [1, 2])
    #
    # @param [String] path
    #   the path to remove versions from
    # @param [Array<Integer>] versions
    #   an array of versions to remove
    #
    # @return [true]
    def delete_versions(path, versions)
      client.post("/v1/#{mount}/delete/#{encode_path(path)}", JSON.fast_generate(versions: versions))

      true
    end

    # Mark specific versions of a secret as active.
    #
    # @example
    #   Vault.kv("secret").undelete_versions("password", [1, 2])
    #
    # @param [String] path
    #   the path to enable versions for
    # @param [Array<Integer>] versions
    #   an array of versions to mark as undeleted
    #
    # @return [true]
    def undelete_versions(path, versions)
      client.post("/v1/#{mount}/undelete/#{encode_path(path)}", JSON.fast_generate(versions: versions))

      true
    end

    # Completely remove a secret and its metadata.
    #
    # @example
    #   Vault.kv("secret").destroy("password")
    #
    # @param [String] path
    #   the path to remove
    #
    # @return [true]
    def destroy(path)
      client.delete("/v1/#{mount}/metadata/#{encode_path(path)}")

      true
    end

    # Completely remove specific versions of a secret.
    #
    # @example
    #   Vault.kv("secret").destroy_versions("password", [1, 2])
    #
    # @param [String] path
    #   the path to remove versions from
    # @param [Array<Integer>] versions
    #   an array of versions to destroy
    #
    # @return [true]
    def destroy_versions(path, versions)
      client.post("/v1/#{mount}/destroy/#{encode_path(path)}", JSON.fast_generate(versions: versions))

      true
    end
  end
end
