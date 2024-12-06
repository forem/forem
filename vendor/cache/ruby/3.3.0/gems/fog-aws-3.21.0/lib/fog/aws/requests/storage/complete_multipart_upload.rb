module Fog
  module AWS
    class Storage
      class Real
        require 'fog/aws/parsers/storage/complete_multipart_upload'

        # Complete a multipart upload
        #
        # @param [String] bucket_name Name of bucket to complete multipart upload for
        # @param [String] object_name Name of object to complete multipart upload for
        # @param [String] upload_id Id of upload to add part to
        # @param [Array<String>] parts Array of etags as Strings for parts
        #
        # @return [Excon::Response]
        #   * body [Hash]: (success)
        #     * Bucket [String] - bucket of new object
        #     * ETag [String] - etag of new object
        #     * Key [String] - key of new object
        #     * Location [String] - location of new object
        #   * body [Hash]: (failure)
        #     * Code [String] - Error status code
        #     * Message [String] - Error description
        #
        # @note This request could fail and still return +200 OK+, so it's important that you check the response.
        # @see http://docs.amazonwebservices.com/AmazonS3/latest/API/mpUploadComplete.html
        #
        def complete_multipart_upload(bucket_name, object_name, upload_id, parts)
          data = "<CompleteMultipartUpload>"
          parts.each_with_index do |part, index|
            data << "<Part>"
            data << "<PartNumber>#{index + 1}</PartNumber>"
            data << "<ETag>#{part}</ETag>"
            data << "</Part>"
          end
          data << "</CompleteMultipartUpload>"
          request({
            :body       => data,
            :expects    => 200,
            :headers    => { 'Content-Length' => data.length },
            :bucket_name => bucket_name,
            :object_name => object_name,
            :method     => 'POST',
            :parser     => Fog::Parsers::AWS::Storage::CompleteMultipartUpload.new,
            :query      => {'uploadId' => upload_id}
          })
        end
      end # Real

      class Mock # :nodoc:all
        require 'fog/aws/requests/storage/shared_mock_methods'
        include Fog::AWS::Storage::SharedMockMethods

        def complete_multipart_upload(bucket_name, object_name, upload_id, parts)
          bucket = verify_mock_bucket_exists(bucket_name)
          upload_info = get_upload_info(bucket_name, upload_id, true)
          body = parts.map { |pid| upload_info[:parts][pid.to_i] }.join
          object = store_mock_object(bucket, object_name, body, upload_info[:options])

          response = Excon::Response.new
          response.status = 200
          response.body = {
            'Location' => "http://#{bucket_name}.s3.amazonaws.com/#{object_name}",
            'Bucket'   => bucket_name,
            'Key'      => object_name,
            'ETag'     => object['ETag'],
          }
          response.headers['x-amz-version-id'] = object['VersionId'] if object['VersionId'] != 'null'
          response
        end
      end # Mock
    end # Storage
  end # AWS
end # Fog
