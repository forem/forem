module Fog
  module AWS
    class AutoScaling
      class Real
        require 'fog/aws/parsers/auto_scaling/basic'

        # Creates a new launch configuration. When created, the new launch
        # configuration is available for immediate use.
        #
        # ==== Parameters
        # * image_id<~String> - Unique ID of the Amazon Machine Image (AMI)
        #   which was assigned during registration.
        # * instance_type<~String> - The instance type of the EC2 instance.
        # * launch_configuration_name<~String> - The name of the launch
        #   configuration to create.
        # * options<~Hash>:
        #   * 'BlockDeviceMappings'<~Array>:
        #     * 'DeviceName'<~String> - The name of the device within Amazon
        #       EC2.
        #     * 'Ebs.SnapshotId'<~String> - The snapshot ID.
        #     * 'Ebs.VolumeSize'<~Integer> - The volume size, in GigaBytes.
        #     * 'VirtualName'<~String> - The virtual name associated with the
        #       device.
        #   * 'IamInstanceProfile'<~String> The name or the Amazon Resource
        #     Name (ARN) of the instance profile associated with the IAM role
        #     for the instance.
        #   * 'InstanceMonitoring.Enabled'<~Boolean> - Enables detailed
        #     monitoring, which is enabled by default.
        #   * 'KernelId'<~String> - The ID of the kernel associated with the
        #     Amazon EC2 AMI.
        #   * 'KeyName'<~String> - The name of the Amazon EC2 key pair.
        #   * 'RamdiskId'<~String> - The ID of the RAM disk associated with the
        #     Amazon EC2 AMI.
        #   * 'SecurityGroups'<~Array> - The names of the security groups with
        #     which to associate Amazon EC2 or Amazon VPC instances.
        #   * 'SpotPrice'<~String> - The maximum hourly price to be paid for
        #     any Spot Instance launched to fulfill the request. Spot Instances
        #     are launched when the price you specify exceeds the current Spot
        #     market price.
        #   * 'UserData'<~String> - The user data available to the launched
        #     Amazon EC2 instances.
        #   * 'EbsOptimized'<~Boolean> - Whether the instance is optimized for
        #     EBS I/O. Not required, default false.
        #   * 'PlacementTenancy'<~String> - The tenancy of the instance. Valid
        #     values: default | dedicated.  Default: default
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'ResponseMetadata'<~Hash>:
        #       * 'RequestId'<~String> - Id of request
        #
        # ==== See Also
        # http://docs.amazonwebservices.com/AutoScaling/latest/APIReference/API_CreateLaunchConfiguration.html
        #
        def create_launch_configuration(image_id, instance_type, launch_configuration_name, options = {})
          if block_device_mappings = options.delete('BlockDeviceMappings')
            block_device_mappings.each_with_index do |mapping, i|
              for key, value in mapping
                options.merge!({ format("BlockDeviceMappings.member.%d.#{key}", i+1) => value })
              end
            end
          end
          if security_groups = options.delete('SecurityGroups')
             options.merge!(AWS.indexed_param('SecurityGroups.member.%d', [*security_groups]))
          end

          if classic_link_groups = options.delete('ClassicLinkVPCSecurityGroups')
            options.merge!(AWS.indexed_param('ClassicLinkVPCSecurityGroups.member.%d', [*classic_link_groups]))
          end
          
          if options['UserData']
            options['UserData'] = Base64.encode64(options['UserData'])
          end
          request({
            'Action'                  => 'CreateLaunchConfiguration',
            'ImageId'                 => image_id,
            'InstanceType'            => instance_type,
            'LaunchConfigurationName' => launch_configuration_name,
            :parser                   => Fog::Parsers::AWS::AutoScaling::Basic.new
          }.merge!(options))
        end
      end

      class Mock
        def create_launch_configuration(image_id, instance_type, launch_configuration_name, options = {})
          if self.data[:launch_configurations].key?(launch_configuration_name)
            raise Fog::AWS::AutoScaling::IdentifierTaken.new("Launch Configuration by this name already exists - A launch configuration already exists with the name #{launch_configuration_name}")
          end
          self.data[:launch_configurations][launch_configuration_name] = {
            'AssociatePublicIpAddress' => nil,
            'BlockDeviceMappings'     => [],
            'CreatedTime'             => Time.now.utc,
            'EbsOptimized'            => false,
            'IamInstanceProfile'      => nil,
            'ImageId'                 => image_id,
            'InstanceMonitoring'      => {'Enabled' => true},
            'InstanceType'            => instance_type,
            'KernelId'                => nil,
            'KeyName'                 => nil,
            'LaunchConfigurationARN'  => Fog::AWS::Mock.arn('autoscaling', self.data[:owner_id], "launchConfiguration:00000000-0000-0000-0000-000000000000:launchConfigurationName/#{launch_configuration_name}", @region),
            'LaunchConfigurationName' => launch_configuration_name,
            'PlacementTenancy'        => nil,
            'RamdiskId'               => nil,
            'SecurityGroups'          => [],
            'UserData'                => nil
          }.merge!(options)

          response = Excon::Response.new
          response.status = 200
          response.body = {
            'ResponseMetadata' => { 'RequestId' => Fog::AWS::Mock.request_id }
          }
          response
        end
      end
    end
  end
end
