module Fog
  module AWS
    class ElasticBeanstalk
      class Real
        require 'fog/aws/parsers/beanstalk/empty'

        # Swaps the CNAMEs of two environments.
        #
        # ==== Options
        # * EnvironmentId
        # * EnvironmentName
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #
        # ==== See Also
        # http://docs.amazonwebservices.com/elasticbeanstalk/latest/api/API_SwapEnvironmentCNAMEs.html
        #
        def swap_environment_cnames(options={})
          request({
                      'Operation'    => 'SwapEnvironmentCNAMEs',
                      :parser     => Fog::Parsers::AWS::ElasticBeanstalk::Empty.new
                  }.merge(options))
        end
      end
    end
  end
end
