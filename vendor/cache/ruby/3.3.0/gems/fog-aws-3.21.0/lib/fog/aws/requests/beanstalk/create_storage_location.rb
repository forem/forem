module Fog
  module AWS
    class ElasticBeanstalk
      class Real
        require 'fog/aws/parsers/beanstalk/create_storage_location'

        # Creates the Amazon S3 storage location for the account.
        #
        # ==== Options
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #
        # ==== See Also
        # http://docs.amazonwebservices.com/elasticbeanstalk/latest/api/API_CreateStorageLocation.html
        #
        def create_storage_location()
          request({
                      'Operation'    => 'CreateStorageLocation',
                      :parser     => Fog::Parsers::AWS::ElasticBeanstalk::CreateStorageLocation.new
                  })
        end
      end
    end
  end
end
