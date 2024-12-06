module Fog
  module AWS
    class Glacier
      class Real
        #  lists in-progress multipart uploads for the specified vault
        #
        # ==== Parameters
        # * name<~String> Name of the vault
        # * options<~Hash>
        #   * limit<~Integer> - The maximum number of items returned in the response. (default 1000)
        #   * marker<~String> - marker used for pagination
        #   * account_id<~String> - The AWS account id. Defaults to the account owning the credentials making the request
        # ==== Returns
        # * response<~Excon::Response>:
        # ==== See Also
        # http://docs.amazonwebservices.com/amazonglacier/latest/dev/api-multipart-list-uploads.html
        #
        def list_multipart_uploads(vault_name, options={})
          account_id = options.delete('account_id') || '-'
          path = "/#{account_id}/vaults/#{Fog::AWS.escape(vault_name)}/multipart-uploads"

          request(
            :expects  => 200,
            :idempotent => true,
            :headers => {},
            :method   => :get,
            :path     => path,
            :query => options
          )
        end
      end
    end
  end
end
