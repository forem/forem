module Fog
  module AWS
    class Glacier
      class Real
        # Delete an archive
        #
        # ==== Parameters
        # * name<~String> Name of the vault to delete
        # * options<~Hash>
        #   * account_id<~String> - The AWS account id. Defaults to the account owning the credentials making the request
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'RequestId'<~String> - Id of the request
        #
        # ==== See Also
        # http://docs.amazonwebservices.com/amazonglacier/latest/dev/api-vault-delete.html
        #
        def delete_archive(name,archive_id,options={})
          account_id = options['account_id'] || '-'
          path = "/#{account_id}/vaults/#{Fog::AWS.escape(name)}/archives/#{archive_id}"
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
