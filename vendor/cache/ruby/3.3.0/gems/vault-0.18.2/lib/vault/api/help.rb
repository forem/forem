# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

require_relative "../client"
require_relative "../response"

module Vault
  # Help is the response from a help query.
  class Help < Response
    # @!attribute [r] help
    #   The help information.
    #   @return [String]
    field :help

    # @!attribute [r] see_also
    #   Additional help documentation to see.
    #   @return [String]
    field :see_also
  end

  class Client
    # Gets help for the given path.
    #
    # @example
    #   Vault.help("secret") #=> #<Vault::Help help="..." see_also="...">
    #
    # @param [String] path
    #   the path to get help for
    #
    # @return [Help]
    def help(path)
      json = self.get("/v1/#{EncodePath.encode_path(path)}", help: 1)
      return Help.decode(json)
    end
  end
end
