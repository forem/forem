module Fog
  module AWS
    class Storage
      class Real
        # Delete an object from S3
        #
        # @param bucket_name [String] Name of bucket containing object to delete
        # @param object_name [String] Name of object to delete
        #
        # @return [Excon::Response] response:
        #   * status [Integer] - 204
        #
        # @see http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectDELETE.html

        def delete_object(bucket_name, object_name, options = {})
          if version_id = options.delete('versionId')
            query = {'versionId' => version_id}
          else
            query = {}
          end

          headers = options
          request({
            :expects    => 204,
            :headers    => headers,
            :bucket_name => bucket_name,
            :object_name => object_name,
            :idempotent => true,
            :method     => 'DELETE',
            :query      => query
          })
        end
      end

      class Mock # :nodoc:all
        def delete_object(bucket_name, object_name, options = {})
          response = Excon::Response.new
          if bucket = self.data[:buckets][bucket_name]
            response.status = 204

            version_id = options.delete('versionId')

            if bucket[:versioning]
              bucket[:objects][object_name] ||= []

              if version_id
                version = bucket[:objects][object_name].find { |object| object['VersionId'] == version_id}

                # S3 special cases the 'null' value to not error out if no such version exists.
                if version || (version_id == 'null')
                  bucket[:objects][object_name].delete(version)
                  bucket[:objects].delete(object_name) if bucket[:objects][object_name].empty?

                  response.headers['x-amz-delete-marker'] = 'true' if version[:delete_marker]
                  response.headers['x-amz-version-id'] = version_id
                else
                  response.status = 400
                  response.body = invalid_version_id_payload(version_id)
                  raise(Excon::Errors.status_error({:expects => 200}, response))
                end
              else
                delete_marker = {
                  :delete_marker    => true,
                  'Key'             => object_name,
                  'VersionId'       => bucket[:versioning] == 'Enabled' ? Fog::Mock.random_base64(32) : 'null',
                  'Last-Modified'   => Fog::Time.now.to_date_header
                }

                # When versioning is suspended, a delete marker is placed if the last object ID is not the value 'null',
                # otherwise the last object is replaced.
                if bucket[:versioning] == 'Suspended' && bucket[:objects][object_name].first['VersionId'] == 'null'
                  bucket[:objects][object_name].shift
                end

                bucket[:objects][object_name].unshift(delete_marker)

                response.headers['x-amz-delete-marker'] = 'true'
                response.headers['x-amz-version-id'] = delete_marker['VersionId']
              end
            else
              if version_id && version_id != 'null'
                response.status = 400
                response.body = invalid_version_id_payload(version_id)
                raise(Excon::Errors.status_error({:expects => 200}, response))
              else
                bucket[:objects].delete(object_name)

                response.headers['x-amz-version-id'] = 'null'
              end
            end
          else
            response.status = 404
            raise(Excon::Errors.status_error({:expects => 204}, response))
          end
          response
        end

        private

        def invalid_version_id_payload(version_id)
          {
            'Error' => {
              'Code' => 'InvalidArgument',
              'Message' => 'Invalid version id specified',
              'ArgumentValue' => version_id,
              'ArgumentName' => 'versionId',
              'RequestId' => Fog::Mock.random_hex(16),
              'HostId' => Fog::Mock.random_base64(65)
            }
          }
        end
      end
    end
  end
end
