module Fog
  module AWS
    class Storage
      class Real
        # Change tag set for an S3 object
        #
        # @param bucket_name [String] Name of bucket to modify object in
        # @param object_name [String] Name of object to modify
        #
        # @param tags [Hash]:
        #   * Key [String]: tag key
        #   * Value [String]: tag value
        #
        # @see https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutObjectTagging.html

        def put_object_tagging(bucket_name, object_name, tags)
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
            :expects  => 200,
            :headers  => {'Content-MD5' => Base64.encode64(OpenSSL::Digest::MD5.digest(data)).chomp!, 'Content-Type' => 'application/xml'},
            :bucket_name => bucket_name,
            :object_name => object_name,
            :method   => 'PUT',
            :query    => {'tagging' => nil}
          })
        end
      end
    end
  end
end
