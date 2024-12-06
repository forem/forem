module Fog
  module AWS
    class Storage
      # From https://docs.aws.amazon.com/AmazonS3/latest/API/API_UploadPartCopy.html
      ALLOWED_UPLOAD_PART_OPTIONS = %i(
        x-amz-copy-source
        x-amz-copy-source-if-match
        x-amz-copy-source-if-modified-since
        x-amz-copy-source-if-none-match
        x-amz-copy-source-if-unmodified-since
        x-amz-copy-source-range
        x-amz-copy-source-server-side-encryption-customer-algorithm
        x-amz-copy-source-server-side-encryption-customer-key
        x-amz-copy-source-server-side-encryption-customer-key-MD5
        x-amz-expected-bucket-owner
        x-amz-request-payer
        x-amz-server-side-encryption-customer-algorithm
        x-amz-server-side-encryption-customer-key
        x-amz-server-side-encryption-customer-key-MD5
        x-amz-source-expected-bucket-owner
      ).freeze

      class Real
        require 'fog/aws/parsers/storage/upload_part_copy_object'

        # Upload a part for a multipart copy
        #
        # @param target_bucket_name [String] Name of bucket to create copy in
        # @param target_object_name [String] Name for new copy of object
        # @param upload_id [String] Id of upload to add part to
        # @param part_number [String] Index of part in upload
        # @param options [Hash]:
        # @option options [String] x-amz-metadata-directive Specifies whether to copy metadata from source or replace with data in request.  Must be in ['COPY', 'REPLACE']
        # @option options [String] x-amz-copy_source-if-match Copies object if its etag matches this value
        # @option options [Time] x-amz-copy_source-if-modified_since Copies object it it has been modified since this time
        # @option options [String] x-amz-copy_source-if-none-match Copies object if its etag does not match this value
        # @option options [Time] x-amz-copy_source-if-unmodified-since Copies object it it has not been modified since this time
        # @option options [Time] x-amz-copy-source-range Specifes the range of bytes to copy from the source object
        #
        # @return [Excon::Response]
        #   * body [Hash]:
        #     * ETag [String] - etag of new object
        #     * LastModified [Time] - date object was last modified
        #
        # @see https://docs.aws.amazon.com/AmazonS3/latest/API/API_UploadPartCopy.html
        #
        def upload_part_copy(target_bucket_name, target_object_name, upload_id, part_number, options = {})
          headers = options
          request({
            :expects    => 200,
            :idempotent => true,
            :headers    => headers,
            :bucket_name => target_bucket_name,
            :object_name => target_object_name,
            :method     => 'PUT',
            :query      => {'uploadId' => upload_id, 'partNumber' => part_number},
            :parser   => Fog::Parsers::AWS::Storage::UploadPartCopyObject.new,
          })
        end
      end # Real

      class Mock # :nodoc:all
        require 'fog/aws/requests/storage/shared_mock_methods'
        include Fog::AWS::Storage::SharedMockMethods

        def upload_part_copy(target_bucket_name, target_object_name, upload_id, part_number, options = {})
          validate_options!(options)

          copy_source = options['x-amz-copy-source']
          copy_range = options['x-amz-copy-source-range']

          raise 'No x-amz-copy-source header provided' unless copy_source
          raise 'No x-amz-copy-source-range header provided' unless copy_range

          source_bucket_name, source_object_name = copy_source.split('/', 2)
          verify_mock_bucket_exists(source_bucket_name)

          source_bucket = self.data[:buckets][source_bucket_name]
          source_object = source_bucket && source_bucket[:objects][source_object_name] && source_bucket[:objects][source_object_name].first
          upload_info = get_upload_info(target_bucket_name, upload_id)

          response = Excon::Response.new

          if source_object
            start_pos, end_pos = byte_range(copy_range, source_object[:body].length)
            upload_info[:parts][part_number] = source_object[:body][start_pos..end_pos]

            response.status = 200
            response.body = {
              # just use the part number as the ETag, for simplicity
              'ETag'          => part_number.to_i,
              'LastModified'  => Time.parse(source_object['Last-Modified'])
            }
            response
          else
            response.status = 404
            raise(Excon::Errors.status_error({:expects => 200}, response))
          end
        end

        def byte_range(range, size)
          matches = range.match(/bytes=(\d*)-(\d*)/)

          return nil unless matches

          end_pos = [matches[2].to_i, size].min

          [matches[1].to_i, end_pos]
        end

        def validate_options!(options)
          options.keys.each do |key|
            raise "Invalid UploadPart option: #{key}" unless ::Fog::AWS::Storage::ALLOWED_UPLOAD_PART_OPTIONS.include?(key.to_sym)
          end
        end
      end # Mock
    end # Storage
  end # AWS
end # Fog
