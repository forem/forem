module Fog
  module AWS
    class Storage
      module GetObjectHttpsUrl
        def get_object_https_url(bucket_name, object_name, expires, options = {})
          get_object_url(bucket_name, object_name, expires, options.merge(:scheme => 'https'))
        end
      end

      class Real
        # Get an expiring object https url from S3
        #
        # @param bucket_name [String] Name of bucket containing object
        # @param object_name [String] Name of object to get expiring url for
        # @param expires [Time] An expiry time for this url
        #
        # @return [Excon::Response] response:
        #   * body [String] - url for object
        #
        # @see http://docs.amazonwebservices.com/AmazonS3/latest/dev/S3_QSAuth.html

        include GetObjectHttpsUrl
      end

      class Mock # :nodoc:all
        include GetObjectHttpsUrl
      end
    end
  end
end
