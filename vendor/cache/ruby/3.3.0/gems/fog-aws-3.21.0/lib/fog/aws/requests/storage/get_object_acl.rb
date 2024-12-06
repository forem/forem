module Fog
  module AWS
    class Storage
      class Real
        require 'fog/aws/parsers/storage/access_control_list'

        # Get access control list for an S3 object
        #
        # @param bucket_name [String] name of bucket containing object
        # @param object_name [String] name of object to get access control list for
        # @param options [Hash]
        # @option options versionId [String] specify a particular version to retrieve
        #
        # @return [Excon::Response] response:
        #   * body [Hash]:
        #     * [AccessControlPolicy [Hash]:
        #       * Owner [Hash]:
        #         * DisplayName [String] - Display name of object owner
        #         * ID [String] - Id of object owner
        #       * AccessControlList [Array]:
        #         * Grant [Hash]:
        #           * Grantee [Hash]:
        #             * DisplayName [String] - Display name of grantee
        #             * ID [String] - Id of grantee
        #             or
        #             * URI [String] - URI of group to grant access for
        #           * Permission [String] - Permission, in [FULL_CONTROL, WRITE, WRITE_ACP, READ, READ_ACP]
        #
        # @see http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectGETacl.html

        def get_object_acl(bucket_name, object_name, options = {})
          unless bucket_name
            raise ArgumentError.new('bucket_name is required')
          end
          unless object_name
            raise ArgumentError.new('object_name is required')
          end
          query = {'acl' => nil}
          if version_id = options.delete('versionId')
            query['versionId'] = version_id
          end
          request({
            :expects    => 200,
            :headers    => {},
            :bucket_name => bucket_name,
            :object_name => object_name,
            :idempotent => true,
            :method     => 'GET',
            :parser     => Fog::Parsers::AWS::Storage::AccessControlList.new,
            :query      => query
          })
        end
      end

      class Mock # :nodoc:all
        require 'fog/aws/requests/storage/acl_utils'

        def get_object_acl(bucket_name, object_name, options = {})
          response = Excon::Response.new
          if acl = self.data[:acls][:object][bucket_name] && self.data[:acls][:object][bucket_name][object_name]
            response.status = 200
            if acl.is_a?(String)
              response.body = Fog::AWS::Storage.acl_to_hash(acl)
            else
              response.body = acl
            end
          else
            response.status = 404
            raise(Excon::Errors.status_error({:expects => 200}, response))
          end
          response
        end
      end
    end
  end
end
