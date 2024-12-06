module Fog
  module AWS
    class Storage
      class Real
        #
        # Abort a multipart upload
        #
        # @param [String] bucket_name Name of bucket to abort multipart upload on
        # @param [String] object_name Name of object to abort multipart upload on
        # @param [String] upload_id Id of upload to add part to
        #
        # @see http://docs.amazonwebservices.com/AmazonS3/latest/API/mpUploadAbort.html
        #
        def abort_multipart_upload(bucket_name, object_name, upload_id)
          request({
            :expects    => 204,
            :headers    => {},
            :bucket_name => bucket_name,
            :object_name => object_name,
            :method     => 'DELETE',
            :query      => {'uploadId' => upload_id}
          })
        end
      end # Real

      class Mock # :nodoc:all
        require 'fog/aws/requests/storage/shared_mock_methods'
        include Fog::AWS::Storage::SharedMockMethods

        def abort_multipart_upload(bucket_name, object_name, upload_id)
          verify_mock_bucket_exists(bucket_name)
          upload_info = get_upload_info(bucket_name, upload_id, true)
          response = Excon::Response.new
          if upload_info
            response.status = 204
            response
          else
            response.status = 404
            raise(Excon::Errors.status_error({:expects => 204}, response))
          end
        end
      end # Mock
    end # Storage
  end # AWS
end # Fog
