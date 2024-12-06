module Fog
  module AWS
    class ElasticBeanstalk
      class Real
        require 'fog/aws/parsers/beanstalk/list_available_solution_stacks'

        # Checks if the specified CNAME is available.
        #
        # ==== Options
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #
        # ==== See Also
        # http://docs.amazonwebservices.com/elasticbeanstalk/latest/api/API_CheckDNSAvailability.html
        #
        def list_available_solution_stacks()
          request({
                      'Operation'    => 'ListAvailableSolutionStacks',
                      :parser     => Fog::Parsers::AWS::ElasticBeanstalk::ListAvailableSolutionStacks.new
                  })
        end
      end
    end
  end
end
