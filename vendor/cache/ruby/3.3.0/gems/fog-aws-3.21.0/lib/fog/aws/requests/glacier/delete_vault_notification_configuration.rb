module Fog
  module AWS
    class Glacier
      class Real
        # Delete vault's notification configuration
        #
        # ==== Parameters
        # * name<~String> Name of the vault
        # * options<~Hash>
        #   * account_id<~String> - The AWS account id. Defaults to the account owning the credentials making the request
        # ==== Returns
        # * response<~Excon::Response>:
        #
        # ==== See Also
        # http://docs.amazonwebservices.com/amazonglacier/latest/dev/api-vault-notifications-delete.html
        #
        def delete_vault_notification_configuration(name,options={})
          account_id = options['account_id'] || '-'
          path = "/#{account_id}/vaults/#{Fog::AWS.escape(name)}/notification-configuration"
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
