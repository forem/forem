require 'fog/aws/models/auto_scaling/activity'

module Fog
  module AWS
    class AutoScaling
      class Activities < Fog::Collection
        model Fog::AWS::AutoScaling::Activity

        attribute :filters

        # Creates a new scaling policy.
        def initialize(attributes={})
          self.filters ||= {}
          super
        end

        def all(filters_arg = filters)
          data = []
          next_token = nil
          filters = filters_arg
          loop do
            result = service.describe_scaling_activities(filters.merge('NextToken' => next_token)).body['DescribeScalingActivitiesResult']
            data += result['Activities']
            next_token = result['NextToken']
            break if next_token.nil?
          end
          load(data)
        end

        def get(identity)
          data = service.describe_scaling_activities('ActivityId' => identity).body['DescribeScalingActivitiesResult']['Activities'].first
          new(data) unless data.nil?
        end
      end
    end
  end
end
