module Fog
  module AWS
    class Storage
      class Real
        require 'fog/aws/parsers/storage/delete_multiple_objects'

        # Delete multiple objects from S3
        # @note For versioned deletes, options should include a version_ids hash, which
        #     maps from filename to an array of versions.
        #     The semantics are that for each (object_name, version) tuple, the
        #     caller must insert the object_name and an associated version (if
        #     desired), so for n versions, the object must be inserted n times.
        #
        # @param bucket_name [String] Name of bucket containing object to delete
        # @param object_names [Array]  Array of object names to delete
        #
        # @return [Excon::Response] response:
        #   * body [Hash]:
        #     * DeleteResult [Array]:
        #       * Deleted [Hash]:
        #         * Key [String] - Name of the object that was deleted
        #         * VersionId [String] - ID for the versioned onject in case of a versioned delete
        #         * DeleteMarker [Boolean] - Indicates if the request accessed a delete marker
        #         * DeleteMarkerVersionId [String] - Version ID of the delete marker accessed
        #       * Error [Hash]:
        #         * Key [String] - Name of the object that failed to be deleted
        #         * VersionId [String] - ID of the versioned object that was attempted to be deleted
        #         * Code [String] - Status code for the result of the failed delete
        #         * Message [String] - Error description
        #
        # @see http://docs.amazonwebservices.com/AmazonS3/latest/API/multiobjectdeleteapi.html

        def delete_multiple_objects(bucket_name, object_names, options = {})
          headers = options.dup
          data = "<Delete>"
          data << "<Quiet>true</Quiet>" if headers.delete(:quiet)
          version_ids = headers.delete('versionId')
          object_names.each do |object_name|
            object_version = version_ids.nil? ? nil : version_ids[object_name]
            if object_version
              object_version = object_version.is_a?(String) ? [object_version] : object_version
              object_version.each do |version_id|
                data << "<Object>"
                data << "<Key>#{CGI.escapeHTML(object_name)}</Key>"
                data << "<VersionId>#{CGI.escapeHTML(version_id)}</VersionId>"
                data << "</Object>"
              end
            else
              data << "<Object>"
              data << "<Key>#{CGI.escapeHTML(object_name)}</Key>"
              data << "</Object>"
            end
          end
          data << "</Delete>"

          headers['Content-Length'] = data.bytesize
          headers['Content-MD5'] = Base64.encode64(OpenSSL::Digest::MD5.digest(data)).
                                   gsub("\n", '')

          request({
            :body       => data,
            :expects    => 200,
            :headers    => headers,
            :bucket_name => bucket_name,
            :method     => 'POST',
            :parser     => Fog::Parsers::AWS::Storage::DeleteMultipleObjects.new,
            :query      => {'delete' => nil}
          })
        end
      end

      class Mock # :nodoc:all
        def delete_multiple_objects(bucket_name, object_names, options = {})
          headers = options.dup
          headers.delete(:quiet)
          response = Excon::Response.new
          if bucket = self.data[:buckets][bucket_name]
            response.status = 200
            response.body = { 'DeleteResult' => [] }
            version_ids = headers.delete('versionId')
            object_names.each do |object_name|
              object_version = version_ids.nil? ? [nil] : version_ids[object_name]
              object_version = object_version.is_a?(String) ? [object_version] : object_version
              object_version.each do |version_id|
                response.body['DeleteResult'] << delete_object_helper(bucket,
                                                                  object_name,
                                                                  version_id)
              end
            end
          else
            response.status = 404
            raise(Excon::Errors.status_error({:expects => 200}, response))
          end
          response
        end

        private

        def delete_object_helper(bucket, object_name, version_id)
          response = { 'Deleted' => {} }
          if bucket[:versioning]
            bucket[:objects][object_name] ||= []

            if version_id
              version = bucket[:objects][object_name].find { |object| object['VersionId'] == version_id}

              # S3 special cases the 'null' value to not error out if no such version exists.
              if version || (version_id == 'null')
                bucket[:objects][object_name].delete(version)
                bucket[:objects].delete(object_name) if bucket[:objects][object_name].empty?

                response['Deleted'] = { 'Key' => object_name,
                                        'VersionId' => version_id,
                                        'DeleteMarker' => 'true',
                                        'DeleteMarkerVersionId' => version_id
                                      }
              else
                response = delete_error_body(object_name,
                                             version_id,
                                             'InvalidVersion',
                                             'Invalid version ID specified')
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

              response['Deleted'] = { 'Key' => object_name,
                                      'VersionId' => delete_marker['VersionId'],
                                      'DeleteMarkerVersionId' =>
                                          delete_marker['VersionId'],
                                      'DeleteMarker' => 'true',
                                    }
            end
          else
            if version_id && version_id != 'null'
              response = delete_error_body(object_name,
                                           version_id,
                                           'InvalidVersion',
                                           'Invalid version ID specified')
              response = invalid_version_id_payload(version_id)
            else
              bucket[:objects].delete(object_name)
              response['Deleted'] = { 'Key' => object_name }
            end
          end
          response
        end

        def delete_error_body(key, version_id, message, code)
          {
            'Error' => {
              'Code'      => code,
              'Message'   => message,
              'VersionId' => version_id,
              'Key'       => key,
            }
          }
        end
      end
    end
  end
end
