module Fog
  module AWS
    class Glacier
      class Real
        # Complete an upload
        #
        # ==== Parameters
        # * name<~String> Name of the vault to upload to
        # * upload_id<~String> The id of the upload to complete
        # * total_size<~Integer> The total archive size
        # * tree_hash<~String> the treehash for the archive
        # * options<~Hash>
        #   * account_id<~String> - The AWS account id. Defaults to the account owning the credentials making the request
        # ==== Returns
        # * response<~Excon::Response>:
        #
        # ==== See Also
        # http://docs.amazonwebservices.com/amazonglacier/latest/dev/api-multipart-complete-upload.html
        #
        def complete_multipart_upload(vault_name, upload_id, total_size, tree_hash, options={})
          account_id = options['account_id'] || '-'
          path = "/#{account_id}/vaults/#{Fog::AWS.escape(vault_name)}/multipart-uploads/#{upload_id}"

          headers = {
            'x-amz-archive-size' => total_size.to_s,
            'x-amz-sha256-tree-hash' => tree_hash
          }

          request(
            :expects  => 201,
            :idempotent => true,
            :headers => headers,
            :method   => :post,
            :path     => path
          )
        end
      end
    end
  end
end
