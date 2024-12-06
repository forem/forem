module Fog
  module AWS
    class ElasticBeanstalk
      class Real
        require 'fog/aws/parsers/beanstalk/empty'

        # Returns AWS resources for this environment.
        #
        # ==== Options
        # * EnvironmentId
        # * EnvironmentName
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #
        # ==== See Also
        # http://docs.amazonwebservices.com/elasticbeanstalk/latest/api/API_RequestEnvironmentInfo.html
        #
        def request_environment_info(options={})
          request({
                      'Operation'    => 'RequestEnvironmentInfo',
                      :parser     => Fog::Parsers::AWS::ElasticBeanstalk::Empty.new
                  }.merge(options))
        end
      end
    end
  end
end
