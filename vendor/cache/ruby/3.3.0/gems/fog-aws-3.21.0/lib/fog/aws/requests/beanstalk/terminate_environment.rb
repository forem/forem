module Fog
  module AWS
    class ElasticBeanstalk
      class Real
        require 'fog/aws/parsers/beanstalk/terminate_environment'

        # Terminates the specified environment.
        #
        # ==== Options
        # * EnvironmentId<~String>: The ID of the environment to terminate.
        # * EnvironmentName<~String>: The name of the environment to terminate.
        # * TerminateResources<~Boolean>: Indicates whether the associated AWS resources should shut down when the
        #     environment is terminated
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #
        # ==== See Also
        # http://docs.amazonwebservices.com/elasticbeanstalk/latest/api/API_TerminateEnvironment.html
        #
        def terminate_environment(options={})
          request({
                      'Operation'    => 'TerminateEnvironment',
                      :parser     => Fog::Parsers::AWS::ElasticBeanstalk::TerminateEnvironment.new
                  }.merge(options))
        end
      end
    end
  end
end
