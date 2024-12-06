module Fog
  module AWS
    class Compute
      class Real
        require 'fog/aws/parsers/compute/describe_placement_groups'

        # Describe all or specified placement groups
        #
        # ==== Parameters
        # * filters<~Hash> - List of filters to limit results with
        #
        # === Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'requestId'<~String> - Id of request
        #     * 'placementGroupSet'<~Array>:
        #       * 'groupName'<~String> - Name of placement group
        #       * 'strategy'<~String> - Strategy of placement group
        #       * 'state'<~String> - State of placement group
        #
        # {Amazon API Reference}[http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DescribePlacementGroups.html]
        def describe_placement_groups(filters = {})
          params = Fog::AWS.indexed_filters(filters)
          request({
            'Action'    => 'DescribePlacementGroups',
            :idempotent => true,
            :parser     => Fog::Parsers::AWS::Compute::DescribePlacementGroups.new
          }.merge!(params))
        end
      end
    end
  end
end
