module Fog
  module Parsers
    module AWS
      module Compute
        class DescribeInstanceAttribute < Fog::Parsers::Base
          def reset
            @response                             = { }
            @in_instanceType                      = false
            @in_kernelId                          = false
            @in_ramdiskId                         = false
            @in_userData                          = false
            @in_disableApiTermination             = false
            @in_instanceInitiatedShutdownBehavior = false
            @in_rootDeviceName                    = false
            @in_blockDeviceMapping                = false
            @in_productCodes                      = false
            @in_ebsOptimized                      = false
            @in_sriovNetSupport                   = false
            @in_sourceDestCheck                   = false
            @in_groupSet                          = false
          end

          def start_element(name, attrs = [])
            super
            case name
            when 'instanceType'
              @in_instanceType   = true
            when 'kernel'
              @in_kernel = true
            when 'ramdisk'
              @in_ramdisk = true
            when 'userData'
              @in_userData = true
            when 'disableApiTermination'
              @in_disableApiTermination = true
            when 'instanceInitiatedShutdownBehavior'
              @in_instanceInitiatedShutdownBehavior = true
            when 'rootDeviceName'
              @in_rootDeviceName = true
            when 'blockDeviceMapping'
              @in_blockDeviceMapping = true
              @block_device_mapping = {}
              unless @response.key?('blockDeviceMapping')
                @response['blockDeviceMapping'] = []
              end
            when 'productCodes'
              @in_productCodes = true
              unless @response.key?('productCodes')
                @response['productCodes'] = []
              end
            when 'ebsOptimized'
              @in_ebsOptimized = true
            when 'sriovNetSupport'
              @in_sriovNetSupport = true
            when 'sourceDestCheck'
              @in_sourceDestCheck = true
            when 'groupSet'
              @in_groupSet = true
              @group = {}
              unless @response.key?('groupSet')
                @response['groupSet'] = []
              end
            end
          end

          def end_element(name)
            if @in_instanceType
              case name
              when 'value'
                @response['instanceType'] = value
              when 'instanceType'
                @in_instanceType = false
              end
            elsif @in_kernel
              case name
              when 'value'
                @response['kernelId'] = value
              when 'kernel'
                @in_kernelId = false
              end
            elsif @in_ramdisk
              case name
              when 'value'
                @response['ramdiskId'] = value
              when 'ramdisk'
                @in_ramdiskId = false
              end
            elsif @in_userData
              case name
              when 'value'
                @response['userData'] = value
              when 'userData'
                @in_userData = false
              end
            elsif @in_disableApiTermination
              case name
              when 'value'
                @response['disableApiTermination'] = (value == 'true')
              when 'disableApiTermination'
                @in_disableApiTermination = false
              end
            elsif @in_instanceInitiatedShutdownBehavior
              case name
              when 'value'
                @response['instanceInitiatedShutdownBehavior'] = value
              when 'instanceInitiatedShutdownBehavior'
                @in_instanceInitiatedShutdownBehavior = false
              end
            elsif @in_rootDeviceName
              case name
              when 'value'
                @response['rootDeviceName'] = value
              when 'rootDeviceName'
                @in_rootDeviceName = false
              end
            elsif @in_blockDeviceMapping
              case name
              when 'item'
                @response["blockDeviceMapping"] << @block_device_mapping
                @block_device_mapping = {}
              when 'volumeId', 'status', 'deviceName'
                @block_device_mapping[name] = value
              when 'attachTime'
                @block_device_mapping['attachTime'] = Time.parse(value)
              when 'deleteOnTermination'
                @block_device_mapping['deleteOnTermination'] = (value == 'true')
              when 'blockDeviceMapping'
                @in_blockDeviceMapping = false
              end
            elsif @in_productCodes
              @response['productCodes'] << value
              case name
              when 'productCodes'
                @in_productCodes = false
              end
            elsif @in_ebsOptimized
              case name
              when 'value'
                @response['ebsOptimized'] = (value == 'true')
              when 'ebsOptimized'
                @in_ebsOptimized = false
              end
            elsif @in_sriovNetSupport
              case name
              when 'value'
                @response["sriovNetSupport"] = value
              when "sriovNetSupport"
                @in_sriovNetSupport = false
              end
            elsif @in_sourceDestCheck
              case name
              when 'value'
                @response['sourceDestCheck'] = (value == 'true')
              when 'sourceDestCheck'
                @in_sourceDestCheck = false
              end
            elsif @in_groupSet
              case name
              when 'item'
                @response['groupSet'] << @group
                @group = {}
              when 'groupId'
                @group["groupId"] = value
              when 'groupSet'
                @in_groupSet = false
              end
            else
              case name
              when 'requestId', 'instanceId'
                @response[name] = value
              end
            end
          end
        end
      end
    end
  end
end
