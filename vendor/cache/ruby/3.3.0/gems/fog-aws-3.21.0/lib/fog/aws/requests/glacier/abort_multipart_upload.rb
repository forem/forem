module Fog
  module AWS
    class Glacier
      class Real
        # Abort an upload
        #
        # ==== Parameters
        # * name<~String> Name of the vault to upload to
        # * upload_id<~String> The id of the upload to complete
        # * options<~Hash>
        #   * account_id<~String> - The AWS account id. Defaults to the account owning the credentials making the request
        # ==== Returns
        # * response<~Excon::Response>:
        #
        # ==== See Also
        # http://docs.amazonwebservices.com/amazonglacier/latest/dev/api-multipart-abort-upload.html
        #
        def abort_multipart_upload(vault_name, upload_id, options={})
          account_id = options['account_id'] || '-'
          path = "/#{account_id}/vaults/#{Fog::AWS.escape(vault_name)}/multipart-uploads/#{upload_id}"

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
