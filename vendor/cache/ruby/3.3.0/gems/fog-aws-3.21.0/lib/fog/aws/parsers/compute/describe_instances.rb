module Fog
  module Parsers
    module AWS
      module Compute
        class DescribeInstances < Fog::Parsers::Base
          def reset
            @block_device_mapping = {}
            @network_interface = {}
            @context = []
            @contexts = ['blockDevices', 'blockDeviceMapping', 'groupSet', 'iamInstanceProfile', 'instancesSet', 'instanceState', 'networkInterfaceSet', 'placement', 'productCodes', 'stateReason', 'tagSet']
            @instance = { 'blockDeviceMapping' => [], 'networkInterfaces' => [], 'iamInstanceProfile' => {}, 'instanceState' => {}, 'monitoring' => {}, 'placement' => {}, 'productCodes' => [], 'stateReason' => {}, 'tagSet' => {} }
            @reservation = { 'groupIds' => [], 'groupSet' => [], 'instancesSet' => [] }
            @response = { 'reservationSet' => [] }
            @tag = {}
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
            when 'arn'
              @instance[@context.last][name] = value
            when 'availabilityZone', 'tenancy'
              @instance['placement'][name] = value
            when 'architecture', 'clientToken', 'dnsName', 'hypervisor', 'imageId',
                  'instanceId', 'instanceType', 'ipAddress', 'kernelId', 'keyName',
                  'instanceLifecycle', 'platform', 'privateDnsName', 'privateIpAddress', 'ramdiskId',
                  'reason', 'requesterId', 'rootDeviceName', 'rootDeviceType',
                  'spotInstanceRequestId', 'virtualizationType'
              @instance[name] = value
            when 'attachTime'
              @block_device_mapping[name] = Time.parse(value)
            when *@contexts
              @context.pop
            when 'code'
              @instance[@context.last][name] = @context.last == 'stateReason' ? value : value.to_i
            when 'message'
              @instance[@context.last][name] = value
            when 'deleteOnTermination'
              @block_device_mapping[name] = (value == 'true')
            when 'deviceName', 'status', 'volumeId'
              @block_device_mapping[name] = value
            when 'subnetId', 'vpcId', 'ownerId', 'networkInterfaceId', 'attachmentId'
              @network_interface[name] = value
              @instance[name] = value
            when 'groupId', 'groupName'
              case @context.last
              when 'groupSet'
                (name == 'groupName') ? current_key = 'groupSet' : current_key = 'groupIds'
                case @context[-2]
                when 'instancesSet'
                  @reservation[current_key] << value
                when 'networkInterfaceSet'
                  @network_interface[current_key] ||= []
                  @network_interface[current_key] << value
                end
              when 'placement'
                @instance['placement'][name] = value
              end
            when 'id'
              @instance[@context.last][name] = value
            when 'item'
              case @context.last
              when 'blockDeviceMapping'
                @instance['blockDeviceMapping'] << @block_device_mapping
                @block_device_mapping = {}
              when 'networkInterfaceSet'
                @instance['networkInterfaces'] << @network_interface
                @network_interface = {}
              when 'instancesSet'
                @reservation['instancesSet'] << @instance
                @instance = { 'blockDeviceMapping' => [], 'networkInterfaces' => [], 'iamInstanceProfile' => {}, 'instanceState' => {}, 'monitoring' => {}, 'placement' => {}, 'productCodes' => [], 'stateReason' => {}, 'tagSet' => {} }
              when 'tagSet'
                @instance['tagSet'][@tag['key']] = @tag['value']
                @tag = {}
              when 'blockDevices'
                # Ignore this one (Eucalyptus specific)
              when nil
                @response['reservationSet'] << @reservation
                @reservation = { 'groupIds' => [], 'groupSet' => [], 'instancesSet' => [] }
              end
            when 'key', 'value'
              @tag[name] = value
            when 'launchTime'
              @instance[name] = Time.parse(value)
            when 'name'
              @instance[@context.last][name] = value
            when 'ownerId', 'reservationId'
              @reservation[name] = value
            when 'requestId', 'nextToken'
              @response[name] = value
            when 'productCode'
              @instance['productCodes'] << value
            when 'state'
              @instance['monitoring'][name] = (value == 'enabled')
            when 'ebsOptimized'
              @instance['ebsOptimized'] = (value == 'true')
            when 'sourceDestCheck'
              if value == 'true'
                @instance[name] = true
              else
                @instance[name] = false
              end
            # Eucalyptus passes status in schema non conforming way
            when 'stateCode'
              @instance['instanceState']['code'] = value
            when 'stateName'
              @instance['instanceState']['name'] = value
            end
          end
        end
      end
    end
  end
end
