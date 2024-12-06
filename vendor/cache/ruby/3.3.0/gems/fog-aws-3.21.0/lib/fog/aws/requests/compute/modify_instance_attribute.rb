module Fog
  module AWS
    class Compute
      class Real
        require 'fog/aws/parsers/compute/basic'

        # Modify instance attributes
        #
        # ==== Parameters
        # * instance_id<~String> - Id of instance to modify
        # * attributes<~Hash>:
        #   'InstanceType.Value'<~String> - New instance type
        #   'Kernel.Value'<~String> - New kernel value
        #   'Ramdisk.Value'<~String> - New ramdisk value
        #   'UserData.Value'<~String> - New userdata value
        #   'DisableApiTermination.Value'<~Boolean> - Change api termination value
        #   'InstanceInitiatedShutdownBehavior.Value'<~String> - New instance initiated shutdown behaviour, in ['stop', 'terminate']
        #   'SourceDestCheck.Value'<~Boolean> - New sourcedestcheck value
        #   'GroupId'<~Array> - One or more groups to add instance to (VPC only)
        #
        # {Amazon API Reference}[http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-ModifyInstanceAttribute.html]
        #
        def modify_instance_attribute(instance_id, attributes)
          params = {}
          params.merge!(Fog::AWS.indexed_param('GroupId', attributes.delete('GroupId') || []))
          params.merge!(attributes)
          request({
            'Action'        => 'ModifyInstanceAttribute',
            'InstanceId'    => instance_id,
            :idempotent     => true,
            :parser         => Fog::Parsers::AWS::Compute::Basic.new
          }.merge!(params))
        end

        def modify_instance_attributes(instance_id, attributes)
          Fog::Logger.deprecation("modify_instance_attributes method is deprecated, use 'modify_instance_attribute' instead")
          modify_instance_attribute(instance_id, attributes)
        end
      end
    end
  end
end
