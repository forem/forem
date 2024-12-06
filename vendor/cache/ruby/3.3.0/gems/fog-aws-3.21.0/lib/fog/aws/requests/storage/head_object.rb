module Fog
  module AWS
    class Storage
      class Real
        # Get headers for an object from S3
        #
        # @param bucket_name [String] Name of bucket to read from
        # @param object_name [String] Name of object to read
        # @param options [Hash]:
        # @option options [String] If-Match Returns object only if its etag matches this value, otherwise returns 412 (Precondition Failed).
        # @option options [Time]   If-Modified-Since Returns object only if it has been modified since this time, otherwise returns 304 (Not Modified).
        # @option options [String] If-None-Match Returns object only if its etag differs from this value, otherwise returns 304 (Not Modified)
        # @option options [Time]   If-Unmodified-Since Returns object only if it has not been modified since this time, otherwise returns 412 (Precodition Failed).
        # @option options [String] Range Range of object to download
        # @option options [String] versionId specify a particular version to retrieve
        #
        # @return [Excon::Response] response:
        #   * body [String] Contents of object
        #   * headers [Hash]:
        #     * Content-Length [String] - Size of object contents
        #     * Content-Type [String] - MIME type of object
        #     * ETag [String] - Etag of object
        #     * Last-Modified - [String] Last modified timestamp for object
        #
        # @see http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectHEAD.html
        #
        def head_object(bucket_name, object_name, options={})
          unless bucket_name
            raise ArgumentError.new('bucket_name is required')
          end
          unless object_name
            raise ArgumentError.new('object_name is required')
          end
          if version_id = options.delete('versionId')
            query = {'versionId' => version_id}
          end
          headers = {}
          headers['If-Modified-Since'] = Fog::Time.at(options['If-Modified-Since'].to_i).to_date_header if options['If-Modified-Since']
          headers['If-Unmodified-Since'] = Fog::Time.at(options['If-Unmodified-Since'].to_i).to_date_header if options['If-Modified-Since']
          headers.merge!(options)
          request({
            :expects    => 200,
            :headers    => headers,
            :bucket_name => bucket_name,
            :object_name => object_name,
            :idempotent => true,
            :method     => 'HEAD',
            :query      => query
          })
        end
      end

      class Mock # :nodoc:all
        def head_object(bucket_name, object_name, options = {})
          response = get_object(bucket_name, object_name, options)
          response.body = nil
          response
        end
      end
    end
  end
end
