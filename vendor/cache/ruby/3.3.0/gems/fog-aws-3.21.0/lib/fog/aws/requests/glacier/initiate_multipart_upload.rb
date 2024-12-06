module Fog
  module AWS
    class Glacier
      class Real
        # This operation initates a multipart upload of an archive to a vault
        #
        # ==== Parameters
        # * name<~String> The vault name
        # * part_size<~Integer> The part size to use. Must be a power of 2 multiple of 1MB (1,2,4,8,16,...)
        # * options<~Hash>
        #   * description<~String> - The archive description
        #   * account_id<~String> - The AWS account id. Defaults to the account owning the credentials making the request
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #
        # ==== See Also
        # http://docs.amazonwebservices.com/amazonglacier/latest/dev/api-multipart-initiate-upload.html
        #
        def initiate_multipart_upload(name, part_size, options={})
          account_id = options['account_id'] || '-'
          path = "/#{account_id}/vaults/#{Fog::AWS.escape(name)}/multipart-uploads"

          headers = {'x-amz-part-size' => part_size.to_s}
          headers['x-amz-archive-description'] = Fog::AWS.escape(options['description']) if options['description']
          request(
            :expects  => 201,
            :headers => headers,
            :method   => 'POST',
            :path     => path
          )
        end
      end
    end
  end
end
