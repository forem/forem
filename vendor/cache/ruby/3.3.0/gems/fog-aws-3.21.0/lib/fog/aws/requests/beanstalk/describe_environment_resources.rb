module Fog
  module AWS
    class ElasticBeanstalk
      class Real
        require 'fog/aws/parsers/beanstalk/describe_environment_resources'

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
        # http://docs.amazonwebservices.com/elasticbeanstalk/latest/api/API_DescribeEnvironmentResources.html
        #
        def describe_environment_resources(options={})
          request({
                      'Operation'    => 'DescribeEnvironmentResources',
                      :parser     => Fog::Parsers::AWS::ElasticBeanstalk::DescribeEnvironmentResources.new
                  }.merge(options))
        end
      end
    end
  end
end
