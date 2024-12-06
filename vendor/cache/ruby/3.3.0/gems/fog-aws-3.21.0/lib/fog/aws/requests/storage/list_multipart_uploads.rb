module Fog
  module AWS
    class Storage
      class Real
        require 'fog/aws/parsers/storage/list_multipart_uploads'

        # List multipart uploads for a bucket
        #
        # @param [String] bucket_name Name of bucket to list multipart uploads for
        # @param [Hash] options config arguments for list.  Defaults to {}.
        # @option options [String] key-marker limits parts to only those that appear lexicographically after this key.
        # @option options [Integer] max-uploads limits number of uploads returned
        # @option options [String] upload-id-marker limits uploads to only those that appear lexicographically after this upload id.
        #
        # @return [Excon::Response] response:
        #   * body [Hash]:
        #     * Bucket [String] Bucket where the multipart upload was initiated
        #     * IsTruncated [Boolean] Whether or not the listing is truncated
        #     * KeyMarker [String] first key in list, only upload ids after this lexographically will appear
        #     * MaxUploads [Integer] Maximum results to return
        #     * NextKeyMarker [String] last key in list, for further pagination
        #     * NextUploadIdMarker [String] last key in list, for further pagination
        #     * Upload [Hash]:
        #       * Initiated [Time] Time when upload was initiated
        #       * Initiator [Hash]:
        #         * DisplayName [String] Display name of upload initiator
        #         * ID [String] Id of upload initiator
        #       * Key [String] Key where multipart upload was initiated
        #       * Owner [Hash]:
        #         * DisplayName [String] Display name of upload owner
        #         * ID [String] Id of upload owner
        #       * StorageClass [String] Storage class of object
        #       * UploadId [String] upload id of upload containing part
        #     * UploadIdMarker [String] first key in list, only upload ids after this lexographically will appear
        #
        # @see http://docs.amazonwebservices.com/AmazonS3/latest/API/mpUploadListMPUpload.html
        #
        def list_multipart_uploads(bucket_name, options = {})
          request({
            :expects  => 200,
            :headers  => {},
            :bucket_name => bucket_name,
            :idempotent => true,
            :method   => 'GET',
            :parser   => Fog::Parsers::AWS::Storage::ListMultipartUploads.new,
            :query    => options.merge!({'uploads' => nil})
          })
        end
      end
    end
  end
end
