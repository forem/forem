module Fog
  module AWS
    class Compute
      class Real
        require 'fog/aws/parsers/compute/basic'

        # Delete a placement group that you own
        #
        # ==== Parameters
        # * group_name<~String> - Name of the placement group.
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'requestId'<~String> - Id of request
        #     * 'return'<~Boolean> - success?
        #
        # {Amazon API Reference}[http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DeletePlacementGroup.html]
        def delete_placement_group(name)
          request(
            'Action'    => 'DeletePlacementGroup',
            'GroupName' => name,
            :idempotent => true,
            :parser     => Fog::Parsers::AWS::Compute::Basic.new
          )
        end
      end
    end
  end
end
