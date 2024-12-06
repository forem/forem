require 'fog/aws/models/auto_scaling/configuration'

module Fog
  module AWS
    class AutoScaling
      class Configurations < Fog::Collection
        model Fog::AWS::AutoScaling::Configuration

        # Creates a new launch configuration
        def initialize(attributes={})
          super
        end

        def all
          data = []
          next_token = nil
          loop do
            result = service.describe_launch_configurations('NextToken' => next_token).body['DescribeLaunchConfigurationsResult']
            data += result['LaunchConfigurations']
            next_token = result['NextToken']
            break if next_token.nil?
          end
          load(data)
        end

        def get(identity)
          data = service.describe_launch_configurations('LaunchConfigurationNames' => identity).body['DescribeLaunchConfigurationsResult']['LaunchConfigurations'].first
	  new(data) unless data.nil?
        end
      end
    end
  end
end
