module Fog
  module AWS
    class ElasticBeanstalk
      class Real
        require 'fog/aws/parsers/beanstalk/create_application'

        # Creates an application that has one configuration template named default and no application versions.
        #
        # ==== Options
        # * ApplicationName<~String>: The name of the application.
        # * Description<~String>: Describes the application.
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #
        # ==== See Also
        # http://docs.amazonwebservices.com/elasticbeanstalk/latest/api/API_CreateApplication.html
        #
        def create_application(options={})
          request({
                      'Operation'    => 'CreateApplication',
                      :parser     => Fog::Parsers::AWS::ElasticBeanstalk::CreateApplication.new
                  }.merge(options))
        end
      end
    end
  end
end
