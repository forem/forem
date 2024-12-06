module Fog
  module AWS
    class Glacier
      class Real
        # Upload an archive
        #
        # ==== Parameters
        # * name<~String> Name of the vault to upload to
        # * body<~String> The data to upload
        # * options<~Hash>
        #   * description<~String> - The archive description
        #   * account_id<~String> - The AWS account id. Defaults to the account owning the credentials making the request
        # ==== Returns
        # * response<~Excon::Response>:
        #
        # ==== See Also
        # http://docs.amazonwebservices.com/amazonglacier/latest/dev/api-archive-post.html
        #
        def create_archive(vault_name, body, options={})
          account_id = options['account_id'] || '-'
          path = "/#{account_id}/vaults/#{Fog::AWS.escape(vault_name)}/archives"

          headers = {
            'Content-Length' => body.bytesize.to_s,
            'x-amz-content-sha256' => OpenSSL::Digest::SHA256.hexdigest(body),
            'x-amz-sha256-tree-hash' => Fog::AWS::Glacier::TreeHash.digest(body)
          }
          headers['x-amz-archive-description'] = Fog::AWS.escape(options['description']) if options['description']

          request(
            :expects  => 201,
            :headers => headers,
            :method   => :post,
            :path     => path,
            :body     => body
          )
        end
      end
    end
  end
end
