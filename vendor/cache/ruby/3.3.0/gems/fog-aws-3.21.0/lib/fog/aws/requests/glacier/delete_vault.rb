module Fog
  module AWS
    class Glacier
      class Real
        # Delete a vault. Amazon Glacier will delete a vault only if there are no archives in the vault as per the last inventory
        # and there have been no writes to the vault since the last inventory
        #
        # ==== Parameters
        # * name<~String> Name of the vault to delete
        # * options<~Hash>
        #   * account_id<~String> - The AWS account id. Defaults to the account owning the credentials making the request
        # ==== Returns
        # * response<~Excon::Response>:
        #
        # ==== See Also
        # http://docs.amazonwebservices.com/amazonglacier/latest/dev/api-vault-delete.html
        #
        def delete_vault(name,options={})
          account_id = options['account_id'] || '-'
          path = "/#{account_id}/vaults/#{Fog::AWS.escape(name)}"
          request(
            :expects  => 204,
            :idempotent => true,
            :headers => {},
            :method   => :delete,
            :path     => path
          )
        end
      end
    end
  end
end
