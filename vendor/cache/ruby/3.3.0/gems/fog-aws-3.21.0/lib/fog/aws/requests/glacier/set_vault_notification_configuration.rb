module Fog
  module AWS
    class Glacier
      class Real
        # Set a vault's notification configuration
        #
        # ==== Parameters
        # * name<~String> Name of the vault
        # * SnsTopic<~String> ARN of the topic to notify
        # * events<~Array> Events you wish to receive. Valid events are ArchiveRetrievalCompleted, InventoryRetrievalCompleted
        # * options<~Hash>
        #   * account_id<~String> - The AWS account id. Defaults to the account owning the credentials making the request
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #
        # ==== See Also
        # http://docs.amazonwebservices.com/amazonglacier/latest/dev/api-vault-notifications-put.html
        #
        def set_vault_notification_configuration(name,sns_topic, events, options={})
          account_id = options['account_id'] || '-'
          path = "/#{account_id}/vaults/#{Fog::AWS.escape(name)}/notification-configuration"
          request(
            :expects  => 204,
            :idempotent => true,
            :headers => {},
            :method   => :put,
            :path     => path,
            :body     => Fog::JSON.encode('SNSTopic' => sns_topic, 'Events' => events)
          )
        end
      end
    end
  end
end
