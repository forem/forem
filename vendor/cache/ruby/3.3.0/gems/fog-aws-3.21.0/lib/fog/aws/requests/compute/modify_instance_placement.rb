module Fog
  module AWS
    class Compute
      class Real
        require 'fog/aws/parsers/compute/basic'

        # Modify instance placement
        #
        # ==== Parameters
        # * instance_id<~String> - Id of instance to modify
        # * attributes<~Hash>:
        #   'Affinity.Value'<~String> - The affinity setting for the instance, in ['default', 'host']
        #   'GroupName.Value'<~String> - The name of the placement group in which to place the instance
        #   'HostId.Value'<~String> - The ID of the Dedicated Host with which to associate the instance
        #   'Tenancy.Value'<~String> - The tenancy for the instance, in ['dedicated', 'host']
        #
        # {Amazon API Reference}[https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_ModifyInstancePlacement.html]
        #
        def modify_instance_placement(instance_id, attributes)
          params = {}
          params.merge!(attributes)
          request({
            'Action'        => 'ModifyInstancePlacement',
            'InstanceId'    => instance_id,
            :idempotent     => true,
            :parser         => Fog::Parsers::AWS::Compute::Basic.new
          }.merge!(params))
        end

      end
    end
  end
end
