module Fog
  module AWS
    class Storage
      class Real
        require 'fog/aws/parsers/storage/get_bucket'

        # List information about objects in an S3 bucket
        #
        # @param bucket_name [String] name of bucket to list object keys from
        # @param options [Hash] config arguments for list.  Defaults to {}.
        # @option options delimiter [String] causes keys with the same string between the prefix
        #     value and the first occurence of delimiter to be rolled up
        # @option options marker [String] limits object keys to only those that appear
        #     lexicographically after its value.
        # @option options max-keys [Integer] limits number of object keys returned
        # @option options prefix [String] limits object keys to those beginning with its value.
        #
        # @return [Excon::Response] response:
        #   * body [Hash]:
        #     * Delimeter [String] - Delimiter specified for query
        #     * IsTruncated [Boolean] - Whether or not the listing is truncated
        #     * Marker [String]- Marker specified for query
        #     * MaxKeys [Integer] - Maximum number of keys specified for query
        #     * Name [String] - Name of the bucket
        #     * Prefix [String] - Prefix specified for query
        #     * CommonPrefixes [Array] - Array of strings for common prefixes
        #     * Contents [Array]:
        #       * ETag [String] - Etag of object
        #       * Key [String] - Name of object
        #       * LastModified [String] - Timestamp of last modification of object
        #       * Owner [Hash]:
        #         * DisplayName [String] - Display name of object owner
        #         * ID [String] - Id of object owner
        #       * Size [Integer] - Size of object
        #       * StorageClass [String] - Storage class of object
        #
        # @see http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGET.html

        def get_bucket(bucket_name, options = {})
          unless bucket_name
            raise ArgumentError.new('bucket_name is required')
          end
          request({
            :expects  => 200,
            :headers  => {},
            :bucket_name => bucket_name,
            :idempotent => true,
            :method   => 'GET',
            :parser   => Fog::Parsers::AWS::Storage::GetBucket.new,
            :query    => options
          })
        end
      end

      class Mock # :nodoc:all
        def get_bucket(bucket_name, options = {})
          prefix, marker, delimiter, max_keys = \
            options['prefix'], options['marker'], options['delimiter'], options['max-keys']
          common_prefixes = []

          unless bucket_name
            raise ArgumentError.new('bucket_name is required')
          end
          response = Excon::Response.new
          if bucket = self.data[:buckets][bucket_name]
            contents = bucket[:objects].values.map(&:first).sort {|x,y| x['Key'] <=> y['Key']}.reject do |object|
                (prefix    && object['Key'][0...prefix.length] != prefix) ||
                (marker    && object['Key'] <= marker) ||
                (delimiter && object['Key'][(prefix ? prefix.length : 0)..-1].include?(delimiter) \
                           && common_prefixes << object['Key'].sub(/^(#{prefix}[^#{delimiter}]+.).*/, '\1')) ||
                object.key?(:delete_marker)
              end.map do |object|
                data = object.reject {|key, value| !['ETag', 'Key', 'StorageClass'].include?(key)}
                data.merge!({
                  'LastModified' => Time.parse(object['Last-Modified']),
                  'Owner'        => bucket['Owner'],
                  'Size'         => object['Content-Length'].to_i
                })
              data
            end
            max_keys = max_keys || 1000
            size = [max_keys, 1000].min
            truncated_contents = contents[0...size]

            response.status = 200
            response.body = {
              'CommonPrefixes'  => common_prefixes.uniq,
              'Contents'        => truncated_contents,
              'IsTruncated'     => truncated_contents.size != contents.size,
              'Marker'          => marker,
              'MaxKeys'         => max_keys,
              'Name'            => bucket['Name'],
              'Prefix'          => prefix
            }
            if max_keys && max_keys < response.body['Contents'].length
                response.body['IsTruncated'] = true
                response.body['Contents'] = response.body['Contents'][0...max_keys]
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
