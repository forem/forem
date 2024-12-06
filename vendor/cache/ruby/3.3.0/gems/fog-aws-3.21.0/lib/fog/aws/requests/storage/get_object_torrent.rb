module Fog
  module AWS
    class Storage
      class Real
        # Get torrent for an S3 object
        #
        # @param bucket_name [String] name of bucket containing object
        # @param object_name [String] name of object to get torrent for
        #
        # @return [Excon::Response] response:
        #   * body [Hash]:
        #     * AccessControlPolicy [Hash:
        #       * Owner [Hash]:
        #         * DisplayName [String] - Display name of object owner
        #         * ID [String] - Id of object owner
        #       * AccessControlList [Array]:
        #         * Grant [Hash]:
        #           * Grantee [Hash]:
        #             * DisplayName [String] - Display name of grantee
        #             * ID [String] - Id of grantee
        #           * Permission [String] - Permission, in [FULL_CONTROL, WRITE, WRITE_ACP, READ, READ_ACP]
        #
        # @see http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectGETtorrent.html

        def get_object_torrent(bucket_name, object_name)
          unless bucket_name
            raise ArgumentError.new('bucket_name is required')
          end
          unless object_name
            raise ArgumentError.new('object_name is required')
          end
          request({
            :expects    => 200,
            :headers    => {},
            :bucket_name => bucket_name,
            :object_name => object_name,
            :idempotent => true,
            :method     => 'GET',
            :query      => {'torrent' => nil}
          })
        end
      end
    end
  end
end
