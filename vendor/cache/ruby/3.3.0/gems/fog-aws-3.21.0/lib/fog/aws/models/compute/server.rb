require 'fog/compute/models/server'

module Fog
  module AWS
    class Compute
      class Server < Fog::Compute::Server
        extend Fog::Deprecation
        deprecate :ip_address, :public_ip_address

        identity  :id,                       :aliases => 'instanceId'

        attr_accessor :architecture
        attribute :ami_launch_index,         :aliases => 'amiLaunchIndex'
        attribute :associate_public_ip,      :aliases => 'associatePublicIP'
        attribute :availability_zone,        :aliases => 'availabilityZone'
        attribute :block_device_mapping,     :aliases => 'blockDeviceMapping'
        attribute :hibernation_options,      :aliases => 'hibernationOptions'
        attribute :network_interfaces,       :aliases => 'networkInterfaces'
        attribute :client_token,             :aliases => 'clientToken'
        attribute :disable_api_termination,  :aliases => 'disableApiTermination'
        attribute :dns_name,                 :aliases => 'dnsName'
        attribute :ebs_optimized,            :aliases => 'ebsOptimized'
        attribute :groups
        attribute :flavor_id,                :aliases => 'instanceType'
        attribute :hypervisor
        attribute :iam_instance_profile,     :aliases => 'iamInstanceProfile'
        attribute :image_id,                 :aliases => 'imageId'
        attr_accessor :instance_initiated_shutdown_behavior
        attribute :kernel_id,                :aliases => 'kernelId'
        attribute :key_name,                 :aliases => 'keyName'
        attribute :created_at,               :aliases => 'launchTime'
        attribute :lifecycle,                :aliases => 'instanceLifecycle'
        attribute :monitoring,               :squash =>  'state'
        attribute :placement_group,          :aliases => 'groupName'
        attribute :platform,                 :aliases => 'platform'
        attribute :product_codes,            :aliases => 'productCodes'
        attribute :private_dns_name,         :aliases => 'privateDnsName'
        attribute :private_ip_address,       :aliases => 'privateIpAddress'
        attribute :public_ip_address,        :aliases => 'ipAddress'
        attribute :ramdisk_id,               :aliases => 'ramdiskId'
        attribute :reason
        attribute :requester_id,             :aliases => 'requesterId'
        attribute :root_device_name,         :aliases => 'rootDeviceName'
        attribute :root_device_type,         :aliases => 'rootDeviceType'
        attribute :security_group_ids,       :aliases => 'securityGroupIds'
        attribute :source_dest_check,        :aliases => 'sourceDestCheck'
        attribute :spot_instance_request_id, :aliases => 'spotInstanceRequestId'
        attribute :state,                    :aliases => 'instanceState', :squash => 'name'
        attribute :state_reason,             :aliases => 'stateReason'
        attribute :subnet_id,                :aliases => 'subnetId'
        attribute :tenancy
        attribute :tags,                     :aliases => 'tagSet'
        attribute :tag_specifications,       :aliases => 'tagSpecifications'
        attribute :user_data
        attribute :virtualization_type,      :aliases => 'virtualizationType'
        attribute :vpc_id,                   :aliases => 'vpcId'

        attr_accessor                        :password
        attr_writer                          :iam_instance_profile_name, :iam_instance_profile_arn

        def initialize(attributes={})
          self.groups     ||= ["default"] unless (attributes[:subnet_id] || attributes[:security_group_ids] || attributes[:network_interfaces])
          self.flavor_id  ||= 't1.micro'

          # Old 'connection' is renamed as service and should be used instead
          prepare_service_value(attributes)

          self.image_id   ||= begin
            self.username ||= 'ubuntu'
            case @service.instance_variable_get(:@region) # Ubuntu 10.04 LTS 64bit (EBS)
            when 'ap-northeast-1'
              'ami-5e0fa45f'
            when 'ap-southeast-1'
              'ami-f092eca2'
            when 'ap-southeast-2'
              'ami-fb8611c1' # Ubuntu 12.04 LTS 64bit (EBS)
            when 'eu-west-1'
              'ami-3d1f2b49'
            when 'sa-east-1'
              'ami-d0429ccd'
            when 'us-east-1'
              'ami-3202f25b'
            when 'us-west-1'
              'ami-f5bfefb0'
            when 'us-west-2'
              'ami-e0ec60d0'
            end
          end
          super
        end

        def addresses
          requires :id

          service.addresses(:server => self)
        end

        def console_output
          requires :id

          service.get_console_output(id)
        end

        def destroy
          requires :id

          service.terminate_instances(id)
          true
        end

        remove_method :flavor_id
        def flavor_id
          @flavor && @flavor.id || attributes[:flavor_id]
        end

        def flavor=(new_flavor)
          @flavor = new_flavor
        end

        def flavor
          @flavor ||= service.flavors.all.find {|flavor| flavor.id == flavor_id}
        end

        def key_pair
          requires :key_name
          service.key_pairs.all({'key-name' => key_name}).first
        end

        def key_pair=(new_keypair)
          self.key_name = new_keypair && new_keypair.name
        end

        def ready?
          state == 'running'
        end

        def reboot
          requires :id
          service.reboot_instances(id)
          true
        end

        def run_instance_options
          raise Fog::Errors::Error.new('Resaving an existing object may create a duplicate') if persisted?
          requires :image_id

          options = {
            'BlockDeviceMapping'          => block_device_mapping,
            'HibernationOptions'          => hibernation_options,
            'NetworkInterfaces'           => network_interfaces,
            'ClientToken'                 => client_token,
            'DisableApiTermination'       => disable_api_termination,
            'EbsOptimized'                => ebs_optimized,
            'IamInstanceProfile.Arn'      => @iam_instance_profile_arn,
            'IamInstanceProfile.Name'     => @iam_instance_profile_name,
            'InstanceInitiatedShutdownBehavior' => instance_initiated_shutdown_behavior,
            'InstanceType'                => flavor_id,
            'KernelId'                    => kernel_id,
            'KeyName'                     => key_name,
            'Monitoring.Enabled'          => monitoring,
            'Placement.AvailabilityZone'  => availability_zone,
            'Placement.GroupName'         => placement_group,
            'Placement.Tenancy'           => tenancy,
            'PrivateIpAddress'            => private_ip_address,
            'RamdiskId'                   => ramdisk_id,
            'SecurityGroup'               => groups,
            'SecurityGroupId'             => security_group_ids,
            'SubnetId'                    => subnet_id,
            'UserData'                    => user_data,
            'TagSpecifications'           => tag_specifications,
          }
          options.delete_if {|key, value| value.nil?}

          # If subnet is defined then this is a Virtual Private Cloud.
          # subnet & security group cannot co-exist. Attempting to specify
          # both subnet and groups will cause an error.  Instead please make
          # use of Security Group Ids when working in a VPC.
          if subnet_id
            options.delete('SecurityGroup')
            if associate_public_ip
              options['NetworkInterface.0.DeviceIndex'] = 0
              options['NetworkInterface.0.AssociatePublicIpAddress'] = associate_public_ip
              options['NetworkInterface.0.SubnetId'] = options['SubnetId']
              options.delete('SubnetId')
              if options['SecurityGroupId'].kind_of?(Array)
                options['SecurityGroupId'].each {|id|
                  options["NetworkInterface.0.SecurityGroupId.#{options['SecurityGroupId'].index(id)}"] = id
                }
              else
                options["NetworkInterface.0.SecurityGroupId.0"] = options['SecurityGroupId']
              end
              options.delete('SecurityGroupId')
              if private_ip_address
                options.delete('PrivateIpAddress')
                options['NetworkInterface.0.PrivateIpAddress'] = private_ip_address
              end
            end
          else
            options.delete('SubnetId')
          end
          options
        end

        def save
          servers = service.servers.save_many(self, 1, 1)
          merge_attributes(servers.first.attributes)
          true
        end

        def setup(credentials = {})
          requires :ssh_ip_address, :username

          commands = [
            %{mkdir .ssh},
            %{passwd -l #{username}},
            %{echo "#{Fog::JSON.encode(Fog::JSON.sanitize(attributes))}" >> ~/attributes.json}
          ]
          if public_key
            commands << %{echo "#{public_key}" >> ~/.ssh/authorized_keys}
          end

          # wait for aws to be ready
          wait_for { sshable?(credentials) }

          Fog::SSH.new(ssh_ip_address, username, credentials).run(commands)
        end

        def start
          requires :id
          service.start_instances(id)
          true
        end

        def stop(options = {})
          requires :id
          service.stop_instances(id, options)
          true
        end

        def volumes
          requires :id
          service.volumes(:server => self)
        end

        #I tried to call it monitoring= and be smart with attributes[]
        #but in #save a merge_attribute is called after run_instance
        #thus making an un-necessary request. Use this until finding a clever solution
        def monitor=(new_monitor)
          if persisted?
            case new_monitor
            when true
              response = service.monitor_instances(identity)
            when false
              response = service.unmonitor_instances(identity)
            else
              raise ArgumentError.new("only Boolean allowed here")
            end
          end
          self.monitoring = new_monitor
        end

        private

        def placement=(new_placement)
          if new_placement.is_a?(Hash)
            merge_attributes(new_placement)
          else
            self.attributes[:placement] = new_placement
          end
        end
      end
    end
  end
end
