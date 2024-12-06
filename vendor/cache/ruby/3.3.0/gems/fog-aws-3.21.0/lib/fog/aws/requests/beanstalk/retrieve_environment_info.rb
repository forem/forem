module Fog
  module AWS
    class ElasticBeanstalk
      class Real
        require 'fog/aws/parsers/beanstalk/retrieve_environment_info'

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
        # http://docs.amazonwebservices.com/elasticbeanstalk/latest/api/API_RetrieveEnvironmentInfo.html
        #
        def retrieve_environment_info(options={})
          request({
                      'Operation'    => 'RetrieveEnvironmentInfo',
                      :parser     => Fog::Parsers::AWS::ElasticBeanstalk::RetrieveEnvironmentInfo.new
                  }.merge(options))
        end
      end
    end
  end
end
