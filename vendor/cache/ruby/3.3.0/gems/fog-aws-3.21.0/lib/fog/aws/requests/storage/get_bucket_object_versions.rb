module Fog
  module AWS
    class Storage
      class Real
        require 'fog/aws/parsers/storage/get_bucket_object_versions'

        # List information about object versions in an S3 bucket
        #
        # @param bucket_name [String] name of bucket to list object keys from
        # @param options [Hash] config arguments for list
        # @option options delimiter [String] causes keys with the same string between the prefix value and the first occurence of delimiter to be rolled up
        # @option options key-marker [String] limits object keys to only those that appear lexicographically after its value.
        # @option options max-keys [Integer] limits number of object keys returned
        # @option options prefix [String] limits object keys to those beginning with its value.
        # @option options version-id-marker [String] limits object versions to only those that appear lexicographically after its value
        #
        # @return [Excon::Response] response:
        #   * body [Hash]:
        #     * Delimeter [String] - Delimiter specified for query
        #     * KeyMarker [String] - Key marker specified for query
        #     * MaxKeys [Integer] - Maximum number of keys specified for query
        #     * Name [String] - Name of the bucket
        #     * Prefix [String] - Prefix specified for query
        #     * VersionIdMarker [String] - Version id marker specified for query
        #     * IsTruncated [Boolean] - Whether or not this is the totality of the bucket
        #     * Versions [Array]:
        #       * DeleteMarker [Hash]:
        #         * IsLatest [Boolean] - Whether or not this is the latest version
        #         * Key [String] - Name of object
        #         * LastModified [String]: Timestamp of last modification of object
        #         * Owner [Hash]:
        #           * DisplayName [String] - Display name of object owner
        #           * ID [String] - Id of object owner
        #         * VersionId [String] - The id of this version
        #       or
        #       * Version [Hash]:
        #         * ETag [String]: Etag of object
        #         * IsLatest [Boolean] - Whether or not this is the latest version
        #         * Key [String] - Name of object
        #         * LastModified [String]: Timestamp of last modification of object
        #         * Owner [Hash]:
        #           * DisplayName [String] - Display name of object owner
        #           * ID [String] - Id of object owner
        #         * Size [Integer] - Size of object
        #         * StorageClass [String] - Storage class of object
        #         * VersionId [String] - The id of this version
        #
        # @see http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETVersion.html

        def get_bucket_object_versions(bucket_name, options = {})
          unless bucket_name
            raise ArgumentError.new('bucket_name is required')
          end
          request({
            :expects  => 200,
            :headers  => {},
            :bucket_name => bucket_name,
            :idempotent => true,
            :method   => 'GET',
            :parser   => Fog::Parsers::AWS::Storage::GetBucketObjectVersions.new,
            :query    => {'versions' => nil}.merge!(options)          })
        end
      end

      class Mock
        def get_bucket_object_versions(bucket_name, options = {})
          delimiter, key_marker, max_keys, prefix, version_id_marker = \
            options['delimiter'], options['key-marker'], options['max-keys'],options['prefix'],options['version-id-marker']

          unless bucket_name
            raise ArgumentError.new('bucket_name is required')
          end

          response = Excon::Response.new

          # Invalid arguments.
          if version_id_marker && !key_marker
            response.status = 400
            response.body = {
              'Error' => {
                'Code' => 'InvalidArgument',
                'Message' => 'A version-id marker cannot be specified without a key marker.',
                'ArgumentValue' => version_id_marker,
                'RequestId' => Fog::Mock.random_hex(16),
                'HostId' => Fog::Mock.random_base64(65)
              }
            }
            raise(Excon::Errors.status_error({:expects => 200}, response))

          # Valid case.
          # TODO: (nirvdrum 12/15/11) It's not clear to me how to actually use version-id-marker, so I didn't implement it below.
          elsif bucket = self.data[:buckets][bucket_name]
            # We need to order results by S3 key, but since our data store is key => [versions], we want to ensure the integrity
            # of the versions as well.  So, sort the keys, then fetch the versions, and then combine them all as a sorted list by
            # flattening the results.
            contents = bucket[:objects].keys.sort.map { |key| bucket[:objects][key] }.flatten.reject do |object|
                (prefix      && object['Key'][0...prefix.length] != prefix) ||
                (key_marker  && object['Key'] <= key_marker) ||
                (delimiter   && object['Key'][(prefix ? prefix.length : 0)..-1].include?(delimiter) \
                             && common_prefixes << object['Key'].sub(/^(#{prefix}[^#{delimiter}]+.).*/, '\1'))
              end.map do |object|
                if object.key?(:delete_marker)
                  tag_name = 'DeleteMarker'
                  extracted_attrs = ['Key', 'VersionId']
                else
                  tag_name = 'Version'
                  extracted_attrs = ['ETag', 'Key', 'StorageClass', 'VersionId']
                end

                data = {}
                data[tag_name] = object.reject { |key, value| !extracted_attrs.include?(key) }
                data[tag_name].merge!({
                  'LastModified' => Time.parse(object['Last-Modified']),
                  'Owner'        => bucket['Owner'],
                  'IsLatest'     => object == bucket[:objects][object['Key']].first
                })

                data[tag_name]['Size'] = object['Content-Length'].to_i if tag_name == 'Version'
              data
            end

            max_keys = max_keys || 1000
            size = [max_keys, 1000].min
            truncated_contents = contents[0...size]

            response.status = 200
            response.body = {
              'Versions'        => truncated_contents,
              'IsTruncated'     => truncated_contents.size != contents.size,
              'KeyMarker'       => key_marker,
              'VersionIdMarker' => version_id_marker,
              'MaxKeys'         => max_keys,
              'Name'            => bucket['Name'],
              'Prefix'          => prefix
            }
            if max_keys && max_keys < response.body['Versions'].length
                response.body['IsTruncated'] = true
                response.body['Versions'] = response.body['Versions'][0...max_keys]
            end

          # Missing bucket case.
          else
            response.status = 404
            response.body = {
              'Error' => {
                'Code' => 'NoSuchBucket',
                'Message' => 'The specified bucket does not exist',
                'BucketName' => bucket_name,
                'RequestId' => Fog::Mock.random_hex(16),
                'HostId' => Fog::Mock.random_base64(65)
              }
            }

            raise(Excon::Errors.status_error({:expects => 200}, response))
          end
          response
        end
      end
    end
  end
end
