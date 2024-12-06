module Fog
  module AWS
    class Storage
      module SharedMockMethods
        def define_mock_acl(bucket_name, object_name, options)
          acl = options['x-amz-acl'] || 'private'
          if !['private', 'public-read', 'public-read-write', 'authenticated-read', 'bucket-owner-read', 'bucket-owner-full-control'].include?(acl)
            raise Excon::Errors::BadRequest.new('invalid x-amz-acl')
          else
            self.data[:acls][:object][bucket_name] ||= {}
            self.data[:acls][:object][bucket_name][object_name] = self.class.acls(acl)
          end
        end

        def parse_mock_data(data)
          data = Fog::Storage.parse_data(data)
          unless data[:body].is_a?(String)
            data[:body].rewind if data[:body].eof?
            data[:body] = data[:body].read
          end
          data
        end

        def verify_mock_bucket_exists(bucket_name)
          if (bucket = self.data[:buckets][bucket_name])
            return bucket
          end

          response = Excon::Response.new
          response.status = 404
          raise(Excon::Errors.status_error({:expects => 200}, response))
        end

        def get_upload_info(bucket_name, upload_id, delete = false)
          if delete
            upload_info = self.data[:multipart_uploads][bucket_name].delete(upload_id)
          else
            upload_info = self.data[:multipart_uploads][bucket_name][upload_id]
          end

          if !upload_info
            response = Excon::Response.new
            response.status = 404
            raise(Excon::Errors.status_error({:expects => 200}, response))
          end

          upload_info
        end

        def store_mock_object(bucket, object_name, body, options)
          object = {
            :body             => body,
            'Content-Type'    => options['Content-Type'],
            'ETag'            => OpenSSL::Digest::MD5.hexdigest(body),
            'Key'             => object_name,
            'Last-Modified'   => Fog::Time.now.to_date_header,
            'Content-Length'  => options['Content-Length'],
            'StorageClass'    => options['x-amz-storage-class'] || 'STANDARD',
            'VersionId'       => bucket[:versioning] == 'Enabled' ? Fog::Mock.random_base64(32) : 'null'
          }

          for key, value in options
            case key
            when 'Cache-Control', 'Content-Disposition', 'Content-Encoding', 'Content-MD5', 'Expires', /^x-amz-meta-/
              object[key] = value
            end
          end

          if bucket[:versioning]
            bucket[:objects][object_name] ||= []

            # When versioning is suspended, putting an object will create a new 'null' version if the latest version
            # is a value other than 'null', otherwise it will replace the latest version.
            if bucket[:versioning] == 'Suspended' && bucket[:objects][object_name].first['VersionId'] == 'null'
              bucket[:objects][object_name].shift
            end

            bucket[:objects][object_name].unshift(object)
          else
            bucket[:objects][object_name] = [object]
          end

          object
        end
      end
    end
  end
end
