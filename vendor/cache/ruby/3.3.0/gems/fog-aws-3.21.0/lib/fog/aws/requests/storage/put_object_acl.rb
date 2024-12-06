module Fog
  module AWS
    class Storage
      class Real
        require 'fog/aws/requests/storage/acl_utils'

        # Change access control list for an S3 object
        #
        # @param [String] bucket_name name of bucket to modify
        # @param [String] object_name name of object to get access control list for
        # @param [Hash] acl
        #   * Owner [Hash]
        #     * ID [String] id of owner
        #     * DisplayName [String] display name of owner
        #   * AccessControlList [Array]
        #     * Grantee [Hash]
        #       * DisplayName [String] Display name of grantee
        #       * ID [String] Id of grantee
        #       or
        #       * EmailAddress [String] Email address of grantee
        #       or
        #       * URI [String] URI of group to grant access for
        #     * Permission [String] Permission, in [FULL_CONTROL, WRITE, WRITE_ACP, READ, READ_ACP]
        # @param [String] acl Permissions, must be in ['private', 'public-read', 'public-read-write', 'authenticated-read']
        # @param [Hash] options
        # @option options [String] versionId specify a particular version to retrieve
        #
        # @see http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectPUTacl.html

        def put_object_acl(bucket_name, object_name, acl, options = {})
          query = {'acl' => nil}
          if version_id = options.delete('versionId')
            query['versionId'] = version_id
          end

          data = ""
          headers = {}

          if acl.is_a?(Hash)
            data = Fog::AWS::Storage.hash_to_acl(acl)
          else
            if !['private', 'public-read', 'public-read-write', 'authenticated-read'].include?(acl)
              raise Excon::Errors::BadRequest.new('invalid x-amz-acl')
            end
            headers['x-amz-acl'] = acl
          end

          headers['Content-MD5'] = Base64.encode64(OpenSSL::Digest::MD5.digest(data)).strip
          headers['Content-Type'] = 'application/json'
          headers['Date'] = Fog::Time.now.to_date_header

          request({
            :body     => data,
            :expects  => 200,
            :headers  => headers,
            :bucket_name => bucket_name,
            :object_name => object_name,
            :method   => 'PUT',
            :query    => query
          })
        end
      end

      class Mock
        def put_object_acl(bucket_name, object_name, acl, options = {})
          if acl.is_a?(Hash)
            self.data[:acls][:object][bucket_name][object_name] = Fog::AWS::Storage.hash_to_acl(acl)
          else
            if !['private', 'public-read', 'public-read-write', 'authenticated-read'].include?(acl)
              raise Excon::Errors::BadRequest.new('invalid x-amz-acl')
            end
            self.data[:acls][:object][bucket_name][object_name] = acl
          end
        end
      end
    end
  end
end
