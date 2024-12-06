module Fog
  module AWS
    class Glacier
      class Real
        # This operation creates a new vault with the specified name.  .
        #
        # ==== Parameters
        # * name<~String> 1-255 characters. must be unique within a region for an AWS account
        # * options<~Hash>
        #   * account_id<~String> - The AWS account id. Defaults to the account owning the credentials making the request
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #
        # ==== See Also
        # http://docs.amazonwebservices.com/amazonglacier/latest/dev/api-vault-put.html
        #
        def create_vault(name,options={})
          account_id = options['account_id'] || '-'
          path = "/#{account_id}/vaults/#{Fog::AWS.escape(name)}"
          request(options.merge({
            :expects  => 201,
            :idempotent => true,
            :headers => {},
            :method   => :put,
            :path     => path,
          }))
        end
      end
    end
  end
end
