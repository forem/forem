module Fog
  module AWS
    class Storage
      class Real
        require 'fog/aws/parsers/storage/copy_object'

        # Copy an object from one S3 bucket to another
        #
        # @param source_bucket_name [String] Name of source bucket
        # @param source_object_name [String] Name of source object
        # @param target_bucket_name [String] Name of bucket to create copy in
        # @param target_object_name [String] Name for new copy of object
        #
        # @param options [Hash]:
        # @option options [String] x-amz-metadata-directive Specifies whether to copy metadata from source or replace with data in request.  Must be in ['COPY', 'REPLACE']
        # @option options [String] x-amz-copy_source-if-match Copies object if its etag matches this value
        # @option options [Time] x-amz-copy_source-if-modified_since Copies object it it has been modified since this time
        # @option options [String] x-amz-copy_source-if-none-match Copies object if its etag does not match this value
        # @option options [Time] x-amz-copy_source-if-unmodified-since Copies object it it has not been modified since this time
        # @option options [String] x-amz-storage-class Default is 'STANDARD', set to 'REDUCED_REDUNDANCY' for non-critical, reproducable data
        #
        #
        # @return [Excon::Response]
        #   * body [Hash]:
        #     * ETag [String] - etag of new object
        #     * LastModified [Time] - date object was last modified
        #
        # @see http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectCOPY.html
        #
        def copy_object(source_bucket_name, source_object_name, target_bucket_name, target_object_name, options = {})
          headers = { 'x-amz-copy-source' => "/#{source_bucket_name}#{object_to_path(source_object_name)}" }.merge!(options)
          request({
            :expects  => 200,
            :headers  => headers,
            :bucket_name => target_bucket_name,
            :object_name => target_object_name,
            :method   => 'PUT',
            :parser   => Fog::Parsers::AWS::Storage::CopyObject.new,
          })
        end
      end

      class Mock # :nodoc:all
        def copy_object(source_bucket_name, source_object_name, target_bucket_name, target_object_name, options = {})
          response = Excon::Response.new
          source_bucket = self.data[:buckets][source_bucket_name]
          source_object = source_bucket && source_bucket[:objects][source_object_name] && source_bucket[:objects][source_object_name].first
          target_bucket = self.data[:buckets][target_bucket_name]

          acl = options['x-amz-acl'] || 'private'
          if !['private', 'public-read', 'public-read-write', 'authenticated-read'].include?(acl)
            raise Excon::Errors::BadRequest.new('invalid x-amz-acl')
          else
            self.data[:acls][:object][target_bucket_name] ||= {}
            self.data[:acls][:object][target_bucket_name][target_object_name] = self.class.acls(acl)
          end

          if source_object && target_bucket
            response.status = 200
            target_object = source_object.dup
            target_object.merge!({'Key' => target_object_name})
            target_bucket[:objects][target_object_name] = [target_object]
            response.body = {
              'ETag'          => target_object['ETag'],
              'LastModified'  => Time.parse(target_object['Last-Modified'])
            }
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
