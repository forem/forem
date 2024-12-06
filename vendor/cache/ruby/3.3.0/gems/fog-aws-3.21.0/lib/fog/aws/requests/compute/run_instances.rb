module Fog
  module AWS
    class Compute
      class Real
        require 'fog/aws/parsers/compute/run_instances'

        # Launch specified instances
        #
        # ==== Parameters
        # * image_id<~String> - Id of machine image to load on instances
        # * min_count<~Integer> - Minimum number of instances to launch. If this
        #   exceeds the count of available instances, no instances will be
        #   launched.  Must be between 1 and maximum allowed for your account
        #   (by default the maximum for an account is 20)
        # * max_count<~Integer> - Maximum number of instances to launch. If this
        #   exceeds the number of available instances, the largest possible
        #   number of instances above min_count will be launched instead. Must
        #   be between 1 and maximum allowed for you account
        #   (by default the maximum for an account is 20)
        # * options<~Hash>:
        #   * 'Placement.AvailabilityZone'<~String> - Placement constraint for instances
        #   * 'Placement.GroupName'<~String> - Name of existing placement group to launch instance into
        #   * 'Placement.Tenancy'<~String> - Tenancy option in ['dedicated', 'default'], defaults to 'default'
        #   * 'BlockDeviceMapping'<~Array>: array of hashes
        #     * 'DeviceName'<~String> - where the volume will be exposed to instance
        #     * 'VirtualName'<~String> - volume virtual device name
        #     * 'Ebs.SnapshotId'<~String> - id of snapshot to boot volume from
        #     * 'Ebs.VolumeSize'<~String> - size of volume in GiBs required unless snapshot is specified
        #     * 'Ebs.DeleteOnTermination'<~Boolean> - specifies whether or not to delete the volume on instance termination
        #     * 'Ebs.Encrypted'<~Boolean> - specifies whether or not the volume is to be encrypted unless snapshot is specified
        #     * 'Ebs.VolumeType'<~String> - Type of EBS volue. Valid options in ['standard', 'io1'] default is 'standard'.
        #     * 'Ebs.Iops'<~String> - The number of I/O operations per second (IOPS) that the volume supports. Required when VolumeType is 'io1'
        #   * 'HibernationOptions'<~Array>: array of hashes
        #     * 'Configured'<~Boolean> - specifies whether or not the instance is configued for hibernation.  This parameter is valid only if the instance meets the hibernation prerequisites.  
        #   * 'NetworkInterfaces'<~Array>: array of hashes
        #     * 'NetworkInterfaceId'<~String> - An existing interface to attach to a single instance
        #     * 'DeviceIndex'<~String> - The device index. Applies both to attaching an existing network interface and creating a network interface
        #     * 'SubnetId'<~String> - The subnet ID. Applies only when creating a network interface
        #     * 'Description'<~String> - A description. Applies only when creating a network interface
        #     * 'PrivateIpAddress'<~String> - The primary private IP address. Applies only when creating a network interface
        #     * 'SecurityGroupId'<~Array> or <~String> - ids of security group(s) for network interface. Applies only when creating a network interface.
        #     * 'DeleteOnTermination'<~String> - Indicates whether to delete the network interface on instance termination.
        #     * 'PrivateIpAddresses.PrivateIpAddress'<~String> - The private IP address. This parameter can be used multiple times to specify explicit private IP addresses for a network interface, but only one private IP address can be designated as primary.
        #     * 'PrivateIpAddresses.Primary'<~Bool> - Indicates whether the private IP address is the primary private IP address.
        #     * 'SecondaryPrivateIpAddressCount'<~Bool> - The number of private IP addresses to assign to the network interface.
        #     * 'AssociatePublicIpAddress'<~String> - Indicates whether to assign a public IP address to an instance in a VPC. The public IP address is assigned to a specific network interface
        #   * 'TagSpecifications'<~Array>: array of hashes
        #     * 'ResourceType'<~String> - Type of resource to apply tags on, e.g: instance or volume
        #     * 'Tags'<~Array> - List of hashs reprensenting tag to be set
        #       * 'Key'<~String> - Tag name
        #       * 'Value'<~String> - Tag value
        #   * 'ClientToken'<~String> - unique case-sensitive token for ensuring idempotency
        #   * 'DisableApiTermination'<~Boolean> - specifies whether or not to allow termination of the instance from the api
        #   * 'SecurityGroup'<~Array> or <~String> - Name of security group(s) for instances (not supported for VPC)
        #   * 'SecurityGroupId'<~Array> or <~String> - id's of security group(s) for instances, use this or SecurityGroup
        #   * 'InstanceInitiatedShutdownBehaviour'<~String> - specifies whether volumes are stopped or terminated when instance is shutdown, in [stop, terminate]
        #   * 'InstanceType'<~String> - Type of instance to boot. Valid options
        #     in ['t1.micro', 't2.nano', 't2.micro', 't2.small', 't2.medium', 'm1.small', 'm1.medium', 'm1.large', 'm1.xlarge', 'c1.medium', 'c1.xlarge', 'c3.large', 'c3.xlarge', 'c3.2xlarge', 'c3.4xlarge', 'c3.8xlarge', 'g2.2xlarge', 'hs1.8xlarge', 'm2.xlarge', 'm2.2xlarge', 'm2.4xlarge', 'cr1.8xlarge', 'm3.xlarge', 'm3.2xlarge', 'hi1.4xlarge', 'cc1.4xlarge', 'cc2.8xlarge', 'cg1.4xlarge', 'i2.xlarge', 'i2.2xlarge', 'i2.4xlarge', 'i2.8xlarge']
        #     default is 'm1.small'
        #   * 'KernelId'<~String> - Id of kernel with which to launch
        #   * 'KeyName'<~String> - Name of a keypair to add to booting instances
        #   * 'Monitoring.Enabled'<~Boolean> - Enables monitoring, defaults to
        #     disabled
        #   * 'PrivateIpAddress<~String> - VPC option to specify ip address within subnet
        #   * 'RamdiskId'<~String> - Id of ramdisk with which to launch
        #   * 'SubnetId'<~String> - VPC option to specify subnet to launch instance into
        #   * 'UserData'<~String> -  Additional data to provide to booting instances
        #   * 'EbsOptimized'<~Boolean> - Whether the instance is optimized for EBS I/O
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'groupSet'<~Array>: groups the instances are members in
        #       * 'groupName'<~String> - Name of group
        #     * 'instancesSet'<~Array>: returned instances
        #       * instance<~Hash>:
        #         * 'amiLaunchIndex'<~Integer> - reference to instance in launch group
        #         * 'architecture'<~String> - architecture of image in [i386, x86_64]
        #         * 'blockDeviceMapping'<~Array>
        #           * 'attachTime'<~Time> - time of volume attachment
        #           * 'deleteOnTermination'<~Boolean> - whether or not to delete volume on termination
        #           * 'deviceName'<~String> - specifies how volume is exposed to instance
        #           * 'status'<~String> - status of attached volume
        #           * 'volumeId'<~String> - Id of attached volume
        #         * 'hibernationOptions'<~Array>
        #           * 'configured'<~Boolean> - whether or not the instance is enabled for hibernation               
        #         * 'dnsName'<~String> - public dns name, blank until instance is running
        #         * 'imageId'<~String> - image id of ami used to launch instance
        #         * 'instanceId'<~String> - id of the instance
        #         * 'instanceState'<~Hash>:
        #           * 'code'<~Integer> - current status code
        #           * 'name'<~String> - current status name
        #         * 'instanceType'<~String> - type of instance
        #         * 'ipAddress'<~String> - public ip address assigned to instance
        #         * 'kernelId'<~String> - Id of kernel used to launch instance
        #         * 'keyName'<~String> - name of key used launch instances or blank
        #         * 'launchTime'<~Time> - time instance was launched
        #         * 'monitoring'<~Hash>:
        #           * 'state'<~Boolean - state of monitoring
        #         * 'placement'<~Hash>:
        #           * 'availabilityZone'<~String> - Availability zone of the instance
        #         * 'privateDnsName'<~String> - private dns name, blank until instance is running
        #         * 'privateIpAddress'<~String> - private ip address assigned to instance
        #         * 'productCodes'<~Array> - Product codes for the instance
        #         * 'ramdiskId'<~String> - Id of ramdisk used to launch instance
        #         * 'reason'<~String> - reason for most recent state transition, or blank
        #         * 'rootDeviceName'<~String> - specifies how the root device is exposed to the instance
        #         * 'rootDeviceType'<~String> - root device type used by AMI in [ebs, instance-store]
        #         * 'ebsOptimized'<~Boolean> - Whether the instance is optimized for EBS I/O
        #     * 'ownerId'<~String> - Id of owner
        #     * 'requestId'<~String> - Id of request
        #     * 'reservationId'<~String> - Id of reservation
        #
        # {Amazon API Reference}[http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-RunInstances.html]
        def run_instances(image_id, min_count, max_count, options = {})
          if block_device_mapping = options.delete('BlockDeviceMapping')
            block_device_mapping.each_with_index do |mapping, index|
              for key, value in mapping
                options.merge!({ format("BlockDeviceMapping.%d.#{key}", index) => value })
              end
            end
          end
          if hibernation_options = options.delete('HibernationOptions')
            hibernation_options.each_with_index do |mapping, index|
              for key, value in mapping
                options.merge!({ format("HibernationOptions.%d.#{key}", index) => value })
              end
            end
          end
          if security_groups = options.delete('SecurityGroup')
            options.merge!(Fog::AWS.indexed_param('SecurityGroup', [*security_groups]))
          end
          if security_group_ids = options.delete('SecurityGroupId')
            options.merge!(Fog::AWS.indexed_param('SecurityGroupId', [*security_group_ids]))
          end
          if options['UserData']
            options['UserData'] = Base64.encode64(options['UserData'])
          end
          if network_interfaces = options.delete('NetworkInterfaces')
            network_interfaces.each_with_index do |mapping, index|
              iface = format("NetworkInterface.%d", index)
              for key, value in mapping
                case key
                when "SecurityGroupId"
                  options.merge!(Fog::AWS.indexed_param("#{iface}.SecurityGroupId", [*value]))
                else
                  options.merge!({ "#{iface}.#{key}" => value })
                end
              end
            end
          end
          if tag_specifications = options.delete('TagSpecifications')
            # From https://docs.aws.amazon.com/sdk-for-ruby/v2/api/Aws/EC2/Client.html#run_instances-instance_method
            # And https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_RunInstances.html
            # Discussed at https://github.com/fog/fog-aws/issues/603
            #
            # Example
            #
            # TagSpecifications: [
            #     {
            #       ResourceType: "instance",
            #       Tags: [
            #         {
            #           Key: "Project",
            #           Value: "MyProject",
            #         },
            #       ],
            #     },
            #     {
            #       ResourceType: "volume",
            #       Tags: [
            #         {
            #           Key: "Project",
            #           Value: "MyProject",
            #         },
            #       ],
            #     },
            # ]
            tag_specifications.each_with_index do |val, idx|
              resource_type = val["ResourceType"]
              tags = val["Tags"]
              options["TagSpecification.#{idx}.ResourceType"] = resource_type
              tags.each_with_index do |tag, tag_idx|
                aws_tag_key = "TagSpecification.#{idx}.Tag.#{tag_idx}.Key"
                aws_tag_value = "TagSpecification.#{idx}.Tag.#{tag_idx}.Value"
                options[aws_tag_key] = tag["Key"]
                options[aws_tag_value] = tag["Value"]
              end
            end
          end

          idempotent = !(options['ClientToken'].nil? || options['ClientToken'].empty?)

          request({
            'Action'    => 'RunInstances',
            'ImageId'   => image_id,
            'MinCount'  => min_count,
            'MaxCount'  => max_count,
            :idempotent => idempotent,
            :parser     => Fog::Parsers::AWS::Compute::RunInstances.new
          }.merge!(options))
        end
      end

      class Mock
        def run_instances(image_id, min_count, max_count, options = {})
          response = Excon::Response.new
          response.status = 200

          group_set = [ (options['SecurityGroup'] || 'default') ].flatten
          instances_set = []
          reservation_id = Fog::AWS::Mock.reservation_id

          if options['KeyName'] && describe_key_pairs('key-name' => options['KeyName']).body['keySet'].empty?
            raise Fog::AWS::Compute::NotFound.new("The key pair '#{options['KeyName']}' does not exist")
          end

          min_count.times do |i|
            instance_id = Fog::AWS::Mock.instance_id
            availability_zone = options['Placement.AvailabilityZone'] || Fog::AWS::Mock.availability_zone(@region)

            block_device_mapping = (options['BlockDeviceMapping'] || []).reduce([]) do |mapping, device|
              device_name           = device.fetch("DeviceName", "/dev/sda1")
              volume_size           = device.fetch("Ebs.VolumeSize", 15)            # @todo should pull this from the image
              delete_on_termination = device.fetch("Ebs.DeleteOnTermination", true) # @todo should pull this from the image

              volume_id = create_volume(availability_zone, volume_size).data[:body]["volumeId"]

              self.data[:volumes][volume_id].merge!("DeleteOnTermination" => delete_on_termination)

              mapping << {
                "deviceName"          => device_name,
                "volumeId"            => volume_id,
                "status"              => "attached",
                "attachTime"          => Time.now,
                "deleteOnTermination" => delete_on_termination,
              }
            end

	    hibernation_options = (options['HibernationOptions'] || []).reduce([]) do |mapping, device|
              configure = device.fetch("Configure", true)

              mapping << {
                "Configure" => configure,
              }
            end

            if options['SubnetId']
              if options['PrivateIpAddress']
                ni_options = {'PrivateIpAddress' => options['PrivateIpAddress']}
              else
                ni_options = {}
              end

              network_interface_id = create_network_interface(options['SubnetId'], ni_options).body['networkInterface']['networkInterfaceId']
            end

            network_interfaces = (options['NetworkInterfaces'] || []).reduce([]) do |mapping, device|
              device_index          = device.fetch("DeviceIndex", 0)
              subnet_id             = device.fetch("SubnetId", options[:subnet_id] ||  Fog::AWS::Mock.subnet_id)
              private_ip_address    = device.fetch("PrivateIpAddress", options[:private_ip_address] || Fog::AWS::Mock.private_ip_address)
              delete_on_termination = device.fetch("DeleteOnTermination", true)
              description           = device.fetch("Description", "mock_network_interface")
              security_group_id     = device.fetch("SecurityGroupId", self.data[:security_groups]['default']['groupId'])
              interface_options     = {
                  "PrivateIpAddress"   => private_ip_address,
                  "GroupSet"           => device.fetch("GroupSet", [security_group_id]),
                  "Description"        => description
              }

              interface_id = device.fetch("NetworkInterfaceId", create_network_interface(subnet_id, interface_options))

              mapping << {
                "networkInterfaceId"  => interface_id,
                "subnetId"            => subnet_id,
                "status"              => "attached",
                "attachTime"          => Time.now,
                "deleteOnTermination" => delete_on_termination,
              }
            end

            instance = {
              'amiLaunchIndex'        => i,
              'associatePublicIP'     => options['associatePublicIP'] || false,
              'architecture'          => 'i386',
              'blockDeviceMapping'    => block_device_mapping,
              'hibernationOptions'    => hibernation_options,
              'networkInterfaces'     => network_interfaces,
              'clientToken'           => options['clientToken'],
              'dnsName'               => nil,
              'ebsOptimized'          => options['EbsOptimized'] || false,
              'hypervisor'            => 'xen',
              'imageId'               => image_id,
              'instanceId'            => instance_id,
              'instanceState'         => { 'code' => 0, 'name' => 'pending' },
              'instanceType'          => options['InstanceType'] || 'm1.small',
              'kernelId'              => options['KernelId'] || Fog::AWS::Mock.kernel_id,
              'keyName'               => options['KeyName'],
              'launchTime'            => Time.now,
              'monitoring'            => { 'state' => options['Monitoring.Enabled'] || false },
              'placement'             => { 'availabilityZone' => availability_zone, 'groupName' => nil, 'tenancy' => options['Placement.Tenancy'] || 'default' },
              'privateDnsName'        => nil,
              'productCodes'          => [],
              'reason'                => nil,
              'rootDeviceName'        => block_device_mapping.first && block_device_mapping.first["deviceName"],
              'rootDeviceType'        => 'instance-store',
              'spotInstanceRequestId' => options['SpotInstanceRequestId'],
              'subnetId'              => options['SubnetId'],
              'virtualizationType'    => 'paravirtual'
            }
            instances_set << instance
            self.data[:instances][instance_id] = instance.merge({
              'groupIds'            => [],
              'groupSet'            => group_set,
              'iamInstanceProfile'  => {},
              'ownerId'             => self.data[:owner_id],
              'reservationId'       => reservation_id,
              'stateReason'         => {}
            })

            if options['SubnetId']
              self.data[:instances][instance_id]['vpcId'] = self.data[:subnets].find{|subnet| subnet['subnetId'] == options['SubnetId'] }['vpcId']

              attachment_id = attach_network_interface(network_interface_id, instance_id, '0').data[:body]['attachmentId']
              modify_network_interface_attribute(network_interface_id, 'attachment', {'attachmentId' => attachment_id, 'deleteOnTermination' => 'true'})
            end
          end
          response.body = {
            'groupSet'      => group_set,
            'instancesSet'  => instances_set,
            'ownerId'       => self.data[:owner_id],
            'requestId'     => Fog::AWS::Mock.request_id,
            'reservationId' => reservation_id
          }
          response
        end
      end
    end
  end
end
