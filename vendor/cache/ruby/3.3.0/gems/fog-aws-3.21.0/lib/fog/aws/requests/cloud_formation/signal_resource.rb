module Fog
  module AWS
    class CloudFormation
      class Real
        require 'fog/aws/parsers/cloud_formation/basic'

        # Sends a signal to the specified resource.
        #
        # @param options Hash]:
        #   * LogicalResourceId [String] The logical ID of the resource that you want to signal.
        #   * StackName [String] The stack name or unique stack ID that includes the resource that you want to signal.
        #   * Status [String] The status of the signal, which is either success or failure.
        #   * UniqueId [String] A unique ID of the signal.
        #
        # @return [Excon::Response]
        #
        # @see http://docs.amazonwebservices.com/AWSCloudFormation/latest/APIReference/API_SignalResource.html

        def signal_resource(logical_resource_id, stack_name, status, unique_id )
          request(
            'Action'    => 'SignalResource',
            'LogicalResourceId' => logical_resource_id,
            'StackName' => stack_name,
            'Status' => status,
            'UniqueId' => unique_id,
            :parser     => Fog::Parsers::AWS::CloudFormation::Basic.new
          )
        end
      end
    end
  end
end
