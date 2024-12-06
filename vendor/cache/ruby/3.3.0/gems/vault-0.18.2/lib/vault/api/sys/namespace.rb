# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

module Vault
  class Namespace < Response
    # @!attribute [r] id
    #   ID of the namespace
    #   @return [String]
    field :id

    # @!attribute [r] path
    #   Path of the namespace, includes parent paths if nested.
    #   @return [String]
    field :path
  end

  class Sys
    # List all namespaces in a given scope. Ignores nested namespaces.
    #
    # @example
    #   Vault.sys.namespaces #=> { :foo => #<struct Vault::Namespace id="xxxx1", path="foo/" }
    #
    #   @return [Hash<Symbol, Namespace>]
    def namespaces(scoped=nil)
      path = ["v1", scoped, "sys", "namespaces"].compact
      json = client.list(path.join("/"))
      json = json[:data] if json[:data]
      if json[:key_info]
        json = json[:key_info]
        hash = {}
        json.each do |k,v|
          hash[k.to_s.chomp("/").to_sym] = Namespace.decode(v)
        end
        hash
      else
        json
      end
    end

    # Create a namespace. Nests the namespace if a namespace header is provided.
    #
    # @example
    #   Vault.sys.create_namespace("foo")
    #
    # @param [String] namespace
    #   the potential path of the namespace, without any parent path provided
    #
    # @return [true]
    def create_namespace(namespace)
      client.put("/v1/sys/namespaces/#{namespace}", {})
      return true
    end

    # Delete a namespace. Raises an error if the namespace provided is not empty.
    #
    # @example
    #   Vault.sys.delete_namespace("foo")
    #
    # @param [String] namespace
    #   the path of the namespace to be deleted
    #
    # @return [true]
    def delete_namespace(namespace)
      client.delete("/v1/sys/namespaces/#{namespace}")
      return true
    end

    # Retrieve a namespace by path.
    #
    # @example
    #   Vault.sys.get_namespace("foo")
    #
    # @param [String] namespace
    #   the path of the namespace ot be retrieved
    #
    # @return [Namespace]
    def get_namespace(namespace)
      json = client.get("/v1/sys/namespaces/#{namespace}")
      if data = json.dig(:data)
        Namespace.decode(data)
      else
        json
      end
    end
  end
end
