module Fog
  module AWS
    class Glacier
      class Real
        # Upload an archive
        #
        # ==== Parameters
        # * name<~String> Name of the vault to upload to
        # * uploadId<~String> Id of the upload
        # * body<~String> The data to upload
        # * offset<~Integer> The offset of the data within the archive
        # * hash<~String> The tree hash for this part
        # * options<~Hash>
        #   * account_id<~String> - The AWS account id. Defaults to the account owning the credentials making the request
        # ==== Returns
        # * response<~Excon::Response>:
        #
        # ==== See Also
        # http://docs.amazonwebservices.com/amazonglacier/latest/dev/api-upload-part.html
        #
        def upload_part(vault_name, upload_id, body, offset, hash, options={})
          account_id = options['account_id'] || '-'
          path = "/#{account_id}/vaults/#{Fog::AWS.escape(vault_name)}/multipart-uploads/#{Fog::AWS.escape(upload_id)}"

          headers = {
            'Content-Length' => body.bytesize.to_s,
            'Content-Range' => "bytes #{offset}-#{offset+body.bytesize-1}/*",
            'x-amz-content-sha256' => OpenSSL::Digest::SHA256.hexdigest(body),
            'x-amz-sha256-tree-hash' => hash
          }

          request(
            :expects  => 204,
            :idempotent => true,
            :headers => headers,
            :method   => :put,
            :path     => path,
            :body     => body
          )
        end
      end
    end
  end
end
