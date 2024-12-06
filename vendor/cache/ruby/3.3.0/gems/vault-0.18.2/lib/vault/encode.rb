# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

module Vault
  module EncodePath

    # Encodes a string according to the rules for URL paths. This is
    # used as opposed to CGI.escape because in a URL path, space
    # needs to be escaped as %20 and CGI.escapes a space as +.
    #
    # @param [String]
    #
    # @return [String]
    def encode_path(path)
      path.b.gsub(%r!([^a-zA-Z0-9_.-/]+)!) { |m|
        '%' + m.unpack('H2' * m.bytesize).join('%').upcase
      }
    end

    module_function :encode_path
  end
end
