module Fog
  module AWS
    class ElasticBeanstalk
      class Real
        require 'fog/aws/parsers/beanstalk/update_application'

        # Updates the specified application to have the specified properties.
        #
        # ==== Options
        # * ApplicationName<~String>: The name of the application to update. If no such application is found,
        #   UpdateApplication returns an InvalidParameterValue error.
        # * Description<~String>: A new description for the application.
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #
        # ==== See Also
        # http://docs.amazonwebservices.com/elasticbeanstalk/latest/api/API_UpdateApplication.html
        #
        def update_application(options)
          request({
                      'Operation'    => 'UpdateApplication',
                      :parser     => Fog::Parsers::AWS::ElasticBeanstalk::UpdateApplication.new
                  }.merge(options))
        end
      end
    end
  end
end
