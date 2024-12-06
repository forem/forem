module Fog
  module AWS
    class Compute
      class Real
        require 'fog/aws/parsers/compute/describe_instance_attribute'
        # Describes an instance attribute value
        #
        # ==== Parameters
        # * instance_id<~String>    - The ID of the instance you want to describe an attribute of
        # * attribute<~String> - The attribute to describe, must be one of the following:
        #    -'instanceType'
        #    -'kernel'
        #    -'ramdisk'
        #    -'userData'
        #    -'disableApiTermination'
        #    -'instanceInitiatedShutdownBehavior'
        #    -'rootDeviceName'
        #    -'blockDeviceMapping'
        #    -'productCodes'
        #    -'sourceDestCheck'
        #    -'groupSet'
        #    -'ebsOptimized'
        #    -'sriovNetSupport'
        #
        # === Returns
        # * response<~Excon::Response>:
        # * body<~Hash>:
        # * 'requestId'<~String>                - Id of request
        # * 'instanceId'<~String>               - The ID of the instance
        # * 'instanceType'<~String>             - Instance type
        # * 'kernelId'<~String>                 - The kernel ID
        # * 'ramdiskId'<~String>                - The RAM disk ID
        # * 'userData'<~String>                 - The Base64-encoded MIME user data
        # * 'disableApiTermination'<~Boolean>   - If the value is true , you can't terminate the instance through the Amazon EC2 console, CLI, or API; otherwise, you can.
        # * 'instanceInitiatedShutdownBehavior'<~String> - Indicates whether an instance stops or terminates when you initiate shutdown from the instance (using the operating system command for system shutdown)
        # * 'rootDeviceName'<~String>           - The name of the root device (for example, /dev/sda1 or /dev/xvda )
        # * 'blockDeviceMapping'<~List>        - The block device mapping of the instance
        # * 'productCodes'<~List>               - A list of product codes
        # * 'ebsOptimized'<~Boolean>            - Indicates whether the instance is optimized for EBS I/O
        # * 'sriovNetSupport'<~String>          - The value to use for a resource attribute
        # * 'sourceDestCheck'<~Boolean>         - Indicates whether source/destination checking is enabled. A value of true means checking is enabled, and false means checking is disabled. This value must be false for a NAT instance to perform NAT
        # * 'groupSet'<~List>                     - The security groups associated with the instance
        # (Amazon API Reference)[http://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_DescribeInstanceAttribute.html]
        def describe_instance_attribute(instance_id, attribute)
          request(
            'Action'       => 'DescribeInstanceAttribute',
            'InstanceId'   => instance_id,
            'Attribute'    => attribute,
            :parser        => Fog::Parsers::AWS::Compute::DescribeInstanceAttribute.new
          )
        end
      end

      class Mock
        def describe_instance_attribute(instance_id, attribute)
          response = Excon::Response.new
          if instance = self.data[:instances].values.find{ |i| i['instanceId'] == instance_id }
            response.status = 200
            response.body = {
              'requestId' => Fog::AWS::Mock.request_id,
              'instanceId'     => instance_id
            }
            case attribute
            when 'kernel'
              response.body[attribute] = instance["kernelId"]
            when 'ramdisk'
              response.body[attribute] = instance["ramdiskId"]
            when 'disableApiTermination'
              response.body[attribute] = false
            when 'instanceInitiatedShutdownBehavior'
              response.body['instanceInitiatedShutdownBehavior'] = 'stop'
            when 'sourceDestCheck'
              response.body[attribute] = true
            when 'sriovNetSupport'
              response.body[attribute] = 'simple'
            else
              response.body[attribute] = instance[attribute]
            end
          response
          else
            raise Fog::AWS::Compute::NotFound.new("The Instance '#{instance_id}' does not exist")
          end
        end
      end
    end
  end
end
