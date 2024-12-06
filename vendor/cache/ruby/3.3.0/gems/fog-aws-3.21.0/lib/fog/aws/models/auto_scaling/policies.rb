require 'fog/aws/models/auto_scaling/policy'

module Fog
  module AWS
    class AutoScaling
      class Policies < Fog::Collection
        model Fog::AWS::AutoScaling::Policy

        attribute :filters

        # Creates a new scaling policy.
        def initialize(attributes={})
          self.filters = attributes
          super(attributes)
        end

        def all(filters_arg = filters)
          data = []
          next_token = nil
          self.filters = filters_arg
          loop do
            result = service.describe_policies(filters.merge('NextToken' => next_token)).body['DescribePoliciesResult']
            data += result['ScalingPolicies']
            next_token = result['NextToken']
            break if next_token.nil?
          end
          load(data)
        end

        def get(identity, auto_scaling_group = nil)
          data = service.describe_policies('PolicyNames' => identity, 'AutoScalingGroupName' => auto_scaling_group).body['DescribePoliciesResult']['ScalingPolicies'].first
          new(data) unless data.nil?
        end
      end
    end
  end
end
