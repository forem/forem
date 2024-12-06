# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

module Vault
  class Request
    attr_reader :client

    def initialize(client)
      @client = client
    end

    # @return [String]
    def to_s
      "#<#{self.class.name}>"
    end

    # @return [String]
    def inspect
      "#<#{self.class.name}:0x#{"%x" % (self.object_id << 1)}>"
    end

    private

    include EncodePath

    # Removes the given header fields from options and returns the result. This
    # modifies the given options in place.
    #
    # @param [Hash] options
    #
    # @return [Hash]
    def extract_headers!(options = {})
      extract = {
        wrap_ttl: Vault::Client::WRAP_TTL_HEADER,
        namespace: Vault::Client::NAMESPACE_HEADER,
      }

      {}.tap do |h|
        extract.each do |k,v|
          if options[k]
            h[v] = options.delete(k)
          end
        end
      end
    end
  end
end
