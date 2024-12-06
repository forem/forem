require 'fog/aws/models/auto_scaling/group'

module Fog
  module AWS
    class AutoScaling
      class Groups < Fog::Collection
        model Fog::AWS::AutoScaling::Group

        attribute :filters

        # Creates a new auto scaling group.
        def initialize(attributes={})
          self.filters = attributes
          super
        end

        def all(filters_arg = filters)
          data = []
          next_token = nil
          filters = filters_arg
          loop do
            result = service.describe_auto_scaling_groups(filters.merge('NextToken' => next_token)).body['DescribeAutoScalingGroupsResult']
            data += result['AutoScalingGroups']
            next_token = result['NextToken']
            break if next_token.nil?
          end
          load(data)
        end

        def get(identity)
          data = service.describe_auto_scaling_groups('AutoScalingGroupNames' => identity).body['DescribeAutoScalingGroupsResult']['AutoScalingGroups'].first
          new(data) unless data.nil?
        end
      end
    end
  end
end
