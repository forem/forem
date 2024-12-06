module Fog
  module AWS
    class Storage
      class Real
        # Change versioning status for an S3 bucket
        #
        # @param bucket_name [String] name of bucket to modify
        # @param status [String] Status to change to in ['Enabled', 'Suspended']
        #
        # @see http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTVersioningStatus.html

        def put_bucket_versioning(bucket_name, status)
          data =
<<-DATA
<VersioningConfiguration xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
  <Status>#{status}</Status>
</VersioningConfiguration>
DATA

          request({
            :body     => data,
            :expects  => 200,
            :headers  => {},
            :bucket_name => bucket_name,
            :method   => 'PUT',
            :query    => {'versioning' => nil}
          })
        end
      end

      class Mock
        def put_bucket_versioning(bucket_name, status)
          response = Excon::Response.new
          bucket = self.data[:buckets][bucket_name]

          if bucket
            if ['Enabled', 'Suspended'].include?(status)
              bucket[:versioning] = status

              response.status = 200
            else
              response.status = 400
              response.body = {
                'Error' => {
                  'Code' => 'MalformedXML',
                  'Message' => 'The XML you provided was not well-formed or did not validate against our published schema',
                  'RequestId' => Fog::Mock.random_hex(16),
                  'HostId' => Fog::Mock.random_base64(65)
                }
              }

              raise(Excon::Errors.status_error({:expects => 200}, response))
            end
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
