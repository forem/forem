module Fog
  module AWS
    class Glacier
      class Real
        # This operation returns information about a vault
        #
        # ==== Parameters
        # * name<~String> Vault name
        # * options<~Hash>
        #   * account_id<~String> - The AWS account id. Defaults to the account owning the credentials making the request
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #
        # ==== See Also
        # http://docs.amazonwebservices.com/amazonglacier/latest/dev/api-vault-get.html
        #
        def describe_vault(name,options={})
          account_id = options['account_id'] || '-'
          path = "/#{account_id}/vaults/#{Fog::AWS.escape(name)}"
          request(
            :expects  => 200,
            :idempotent => true,
            :headers => {},
            :method   => :get,
            :path     => path
          )
        end
      end
    end
  end
end
