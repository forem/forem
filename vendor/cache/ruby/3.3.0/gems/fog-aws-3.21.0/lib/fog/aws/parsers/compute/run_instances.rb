module Fog
  module Parsers
    module AWS
      module Compute
        class RunInstances < Fog::Parsers::Base
          def reset
            @block_device_mapping = {}
            @network_interfaces = {}
            @context = []
            @contexts = ['networkInterfaces', 'blockDeviceMapping', 'groupSet', 'placement', 'productCodes']
            @instance = { 'networkInterfaces' => [], 'blockDeviceMapping' => [], 'instanceState' => {}, 'monitoring' => {}, 'placement' => {}, 'productCodes' => [] }
            @response = { 'groupSet' => [], 'instancesSet' => [] }
          end

          def start_element(name, attrs = [])
            super
            if @contexts.include?(name)
              @context.push(name)
            end
          end

          def end_element(name)
            case name
            when 'amiLaunchIndex'
              @instance[name] = value.to_i
            when 'architecture', 'clientToken', 'dnsName', 'hypervisor', 'imageId',
                  'instanceId', 'instanceType', 'ipAddress', 'kernelId', 'keyName',
                  'instanceLifecycle', 'privateDnsName', 'privateIpAddress', 'ramdiskId',
                  'reason', 'requesterId', 'rootDeviceType', 'sourceDestCheck',
                  'spotInstanceRequestId', 'virtualizationType'
              @instance[name] = value
            when 'availabilityZone', 'tenancy'
              @instance['placement'][name] = value
            when 'attachTime'
              @block_device_mapping[name] = Time.parse(value)
            when *@contexts
              @context.pop
            when 'code'
              @instance['instanceState'][name] = value.to_i
            when 'deleteOnTermination'
              @block_device_mapping[name] = (value == 'true')
              @network_interfaces[name] = (value == 'true')
            when 'deviceName', 'status', 'volumeId'
              @block_device_mapping[name] = value
            when 'networkInterfaceId'
              @network_interfaces[name] = value
            when 'groupId'
              @response['groupSet'] << value
            when 'groupName'
              case @context.last
              when 'groupSet'
                @response['groupSet'] << value
              when 'placement'
                @instance['placement'][name] = value
              end
            when 'item'
              case @context.last
              when 'blockDeviceMapping'
                @instance['blockDeviceMapping'] << @block_device_mapping
                @block_device_mapping = {}
              when 'networkInterfaces'
                @instance['networkInterfaces'] << @network_interfaces
                @network_interfaces = {}
              when nil
                @response['instancesSet'] << @instance
                @instance = { 'networkInterfaces' => [], 'blockDeviceMapping' => [], 'instanceState' => {}, 'monitoring' => {}, 'placement' => {}, 'productCodes' => [] }
              end
            when 'launchTime'
              @instance[name] = Time.parse(value)
            when 'name'
              @instance['instanceState'][name] = value
            when 'ownerId', 'requestId', 'reservationId'
              @response[name] = value
            when 'product_code'
              @instance['productCodes'] << value
            when 'state'
              @instance['monitoring'][name] = (value == 'true')
            when 'subnetId'
              @response[name] = value
            when 'ebsOptimized'
              @instance['ebsOptimized'] = (value == 'true')
            when 'associatePublicIP'
              @instance['associatePublicIP'] = (value == 'true')
            end
          end
        end
      end
    end
  end
end
