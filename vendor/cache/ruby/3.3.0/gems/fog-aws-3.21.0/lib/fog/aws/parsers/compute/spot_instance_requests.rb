module Fog
  module Parsers
    module AWS
      module Compute
        class SpotInstanceRequests < Fog::Parsers::Base
          def reset
            @block_device_mapping = {}
            @context = []
            @contexts = ['blockDeviceMapping', 'groupSet', 'iamInstanceProfile', 'networkInterfaceSet']
            @spot_instance_request = { 'launchSpecification' => { 'iamInstanceProfile' => {}, 'blockDeviceMapping' => [], 'groupSet' => [] } }
            @response = { 'spotInstanceRequestSet' => [] }
          end

          def start_element(name, attrs = [])
            super
            if @contexts.include?(name)
              @context.push(name)
            end
          end

          def end_element(name)
            case name
            when 'attachTime'
              @block_device_mapping[name] = Time.parse(value)
            when *@contexts
              @context.pop
            when 'code', 'message'
              @spot_instance_request['fault'] ||= {}
              @spot_instance_request['fault'][name] = value
            when 'createTime'
              @spot_instance_request[name] = Time.parse(value)
            when 'deleteOnTermination'
              @block_device_mapping[name] = (value == 'true')
            when 'deviceName', 'status', 'volumeId'
              @block_device_mapping[name] = value
            when 'groupId'
              if !@context.include?('networkInterfaceSet')
                @spot_instance_request['launchSpecification']['groupSet'] << value
              end
            when 'arn', 'name'
              @spot_instance_request['launchSpecification']['iamInstanceProfile'][name] = value
            when 'instanceId', 'launchedAvailabilityZone', 'productDescription', 'spotInstanceRequestId', 'state', 'type'
              @spot_instance_request[name] = value
            when 'item'
              case @context.last
              when 'blockDeviceMapping'
                @spot_instance_request['launchSpecification']['blockDeviceMapping'] << @block_device_mapping
                @block_device_mapping = {}
              when nil
                @response['spotInstanceRequestSet'] << @spot_instance_request
                @spot_instance_request = { 'launchSpecification' => { 'iamInstanceProfile' => {}, 'blockDeviceMapping' => [], 'groupSet' => [] } }
              end
            when 'imageId', 'instanceType', 'keyname', 'subnetId'
              @spot_instance_request['launchSpecification'][name] = value
            when 'ebsOptimized'
              @spot_instance_request['launchSpecification'][name] = value == 'true'
            when 'enabled'
              @spot_instance_request['launchSpecification']['monitoring'] = (value == 'true')
            when 'requestId'
              @response[name] = value
            when 'spotPrice'
              @spot_instance_request[name] = value.to_f
            end
          end
        end
      end
    end
  end
end
