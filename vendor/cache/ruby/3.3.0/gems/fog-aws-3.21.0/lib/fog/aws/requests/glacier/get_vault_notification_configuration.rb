module Fog
  module AWS
    class Glacier
      class Real
        # Get a vault's notification configuration
        #
        # ==== Parameters
        # * name<~String> Name of the vault
        # * options<~Hash>
        #   * account_id<~String> - The AWS account id. Defaults to the account owning the credentials making the request
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #
        # ==== See Also
        # http://docs.amazonwebservices.com/amazonglacier/latest/dev/api-vault-notifications-get.html
        #
        def get_vault_notification_configuration(name,options={})
          account_id = options['account_id'] || '-'
          path = "/#{account_id}/vaults/#{Fog::AWS.escape(name)}/notification-configuration"
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
