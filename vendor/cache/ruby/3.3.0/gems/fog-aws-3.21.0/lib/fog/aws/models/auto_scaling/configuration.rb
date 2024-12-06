module Fog
  module AWS
    class AutoScaling
      class Configuration < Fog::Model
        identity  :id,                    :aliases => 'LaunchConfigurationName'
        attribute :arn,                   :aliases => 'LaunchConfigurationARN'
        attribute :associate_public_ip,   :aliases => 'AssociatePublicIpAddress'
        attribute :block_device_mappings, :aliases => 'BlockDeviceMappings'
        attribute :created_at,            :aliases => 'CreatedTime'
        attribute :ebs_optimized,         :aliases => 'EbsOptimized'
        attribute :iam_instance_profile,  :aliases => 'IamInstanceProfile'
        attribute :image_id,              :aliases => 'ImageId'
        #attribute :instance_monitoring,   :aliases => 'InstanceMonitoring'
        attribute :instance_monitoring,   :aliases => 'InstanceMonitoring', :squash => 'Enabled'
        attribute :instance_type,         :aliases => 'InstanceType'
        attribute :kernel_id,             :aliases => 'KernelId'
        attribute :key_name,              :aliases => 'KeyName'
        attribute :ramdisk_id,            :aliases => 'RamdiskId'
        attribute :security_groups,       :aliases => 'SecurityGroups'
        attribute :user_data,             :aliases => 'UserData'
        attribute :spot_price,            :aliases => 'SpotPrice'
        attribute :placement_tenancy,     :aliases => 'PlacementTenancy'
        attribute :classic_link_vpc_id,   :aliases => 'ClassicLinkVPCId'
        attribute :classic_link_security_groups, :aliases => 'ClassicLinkVPCSecurityGroups'

        def initialize(attributes={})
          #attributes[:availability_zones] ||= %w(us-east-1a us-east-1b us-east-1c us-east-1d)
          #attributes['ListenerDescriptions'] ||= [{
          #  'Listener' => {'LoadBalancerPort' => 80, 'InstancePort' => 80, 'Protocol' => 'http'},
          #  'PolicyNames' => []
          #}]
          #attributes['Policies'] ||= {'AppCookieStickinessPolicies' => [], 'LBCookieStickinessPolicies' => []}
          super
        end

        def ready?
          # AutoScaling requests are synchronous
          true
        end

        def save
          requires :id
          requires :image_id
          requires :instance_type

          options = Hash[self.class.aliases.map { |key, value| [key, send(value)] }]
          options.delete_if { |key, value| value.nil? }
          service.create_launch_configuration(image_id, instance_type, id, options) #, listeners.map{|l| l.to_params})

          # reload instead of merge attributes b/c some attrs (like HealthCheck)
          # may be set, but only the DNS name is returned in the create_load_balance
          # API call
          reload
        end

        def reload
          super
          self
        end

        def destroy
          requires :id
          service.delete_launch_configuration(id)
        end
      end
    end
  end
end
