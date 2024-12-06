module Fog
  module AWS
    class Glacier
      class Real
        #  lists the parts of an archive that have been uploaded in a specific multipart upload
        #
        # ==== Parameters
        # * name<~String> Name of the vault
        # * upload_id<~String> The id of the upload
        # * options<~Hash>
        #   * limit<~Integer> - The maximum number of items returned in the response. (default 1000)
        #   * marker<~String> - marker used for pagination
        #   * account_id<~String> - The AWS account id. Defaults to the account owning the credentials making the request
        # ==== Returns
        # * response<~Excon::Response>:
        # ==== See Also
        # http://docs.amazonwebservices.com/amazonglacier/latest/dev/api-multipart-list-parts.html
        #
        def list_parts(vault_name, upload_id, options={})
          account_id = options.delete('account_id') || '-'
          path = "/#{account_id}/vaults/#{Fog::AWS.escape(vault_name)}/multipart-uploads/#{Fog::AWS.escape(upload_id)}"

          request(
            :expects  => 200,
            :idempotent => true,
            :headers => {},
            :method   => :get,
            :path     => path,
            :query    => options
          )
        end
      end
    end
  end
end
