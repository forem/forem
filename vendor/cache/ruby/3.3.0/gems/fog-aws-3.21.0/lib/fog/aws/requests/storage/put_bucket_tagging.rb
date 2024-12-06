module Fog
  module AWS
    class Storage
      class Real
        # Change tag set for an S3 bucket
        #
        # @param bucket_name [String] name of bucket to modify
        # @param tags [Hash]:
        #   * Key [String]: tag key
        #   * Value [String]: tag value
        #
        # @see http://docs.aws.amazon.com/AmazonS3/latest/API/RESTBucketPUTtagging.html

        def put_bucket_tagging(bucket_name, tags)
          tagging = tags.map do |k,v|
            "<Tag><Key>#{k}</Key><Value>#{v}</Value></Tag>"
          end.join("\n")
          data =
<<-DATA
<Tagging xmlns="http://doc.s3.amazonaws.com/2006-03-01" >
  <TagSet>
    #{tagging}
  </TagSet>
</Tagging>
DATA

          request({
            :body     => data,
            :expects  => 204,
            :headers  => {'Content-MD5' => Base64.encode64(OpenSSL::Digest::MD5.digest(data)).chomp!, 'Content-Type' => 'application/xml'},
            :bucket_name => bucket_name,
            :method   => 'PUT',
            :query    => {'tagging' => nil}
          })
        end
      end

      class Mock # :nodoc:all
        def put_bucket_tagging(bucket_name, tags)
          response = Excon::Response.new

          if self.data[:buckets][bucket_name]
            self.data[:bucket_tagging][bucket_name] = tags
            response.status = 204
          else
            response.status = 404
            raise(Excon::Errors.status_error({:expects => 204}, response))
          end

          response
        end
      end
    end
  end
end
