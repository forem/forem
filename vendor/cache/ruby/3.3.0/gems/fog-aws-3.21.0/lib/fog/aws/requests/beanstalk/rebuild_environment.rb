module Fog
  module AWS
    class ElasticBeanstalk
      class Real
        require 'fog/aws/parsers/beanstalk/empty'

        # Deletes and recreates all of the AWS resources (for example: the Auto Scaling group, load balancer, etc.)
        # for a specified environment and forces a restart.
        #
        # ==== Options
        # * EnvironmentId
        # * EnvironmentName
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #
        # ==== See Also
        # http://docs.amazonwebservices.com/elasticbeanstalk/latest/api/API_RebuildEnvironment.html
        #
        def rebuild_environment(options={})
          request({
                      'Operation'    => 'RebuildEnvironment',
                      :parser     => Fog::Parsers::AWS::ElasticBeanstalk::Empty.new
                  }.merge(options))
        end
      end
    end
  end
end
