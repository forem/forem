require 'fog/aws/models/auto_scaling/instance'

module Fog
  module AWS
    class AutoScaling
      class Instances < Fog::Collection
        model Fog::AWS::AutoScaling::Instance

        def all
          data = []
          next_token = nil
          loop do
            result = service.describe_auto_scaling_instances('NextToken' => next_token).body['DescribeAutoScalingInstancesResult']
            data += result['AutoScalingInstances']
            next_token = result['NextToken']
            break if next_token.nil?
          end
          load(data)
        end

        def get(identity)
          data = service.describe_auto_scaling_instances('InstanceIds' => identity).body['DescribeAutoScalingInstancesResult']['AutoScalingInstances'].first
          new(data) unless data.nil?
        end
      end
    end
  end
end
