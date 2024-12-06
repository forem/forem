module Fog
  module AWS
    class Compute
      class Real
        require 'fog/aws/parsers/compute/basic'

        # Create a new placement group
        #
        # ==== Parameters
        # * group_name<~String> - Name of the placement group.
        # * strategy<~String> - Placement group strategy. Valid options in ['cluster']
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'requestId'<~String> - Id of request
        #     * 'return'<~Boolean> - success?
        #
        # {Amazon API Reference}[http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-CreatePlacementGroup.html]
        def create_placement_group(name, strategy)
          request(
            'Action'            => 'CreatePlacementGroup',
            'GroupName'         => name,
            'Strategy'          => strategy,
            :parser             => Fog::Parsers::AWS::Compute::Basic.new
          )
        end
      end
    end
  end
end
