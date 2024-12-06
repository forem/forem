# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

require_relative "defaults"

module Vault
  module Configurable
    def self.keys
      @keys ||= [
        :address,
        :token,
        :hostname,
        :namespace,
        :open_timeout,
        :proxy_address,
        :proxy_password,
        :proxy_port,
        :proxy_username,
        :pool_size,
        :pool_timeout,
        :read_timeout,
        :ssl_ciphers,
        :ssl_pem_contents,
        :ssl_pem_file,
        :ssl_pem_passphrase,
        :ssl_ca_cert,
        :ssl_ca_path,
        :ssl_cert_store,
        :ssl_verify,
        :ssl_timeout,
        :timeout,
      ]
    end

    Vault::Configurable.keys.each(&method(:attr_accessor))

    # Configure yields self for block-style configuration.
    #
    # @yield [self]
    def configure
      yield self
    end

    # The list of options for this configurable.
    #
    # @return [Hash<Symbol, Object>]
    def options
      Hash[*Vault::Configurable.keys.map do |key|
        [key, instance_variable_get(:"@#{key}")]
      end.flatten]
    end
  end
end
