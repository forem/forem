module Fog
  module Parsers
    module AWS
      module Compute
        class DescribeImageAttribute < Fog::Parsers::Base
          def reset
            @response                             = { }
            @in_description                       = false
            @in_kernelId                          = false
            @in_ramdiskId                         = false
            @in_launchPermission                  = false
            @in_productCodes                      = false
            @in_blockDeviceMapping                = false
            @in_sriovNetSupport                   = false
          end

          def start_element(name, attrs = [])
            super
            case name
            when 'description'
              @in_description = true
            when 'kernel'
              @in_kernel = true
            when 'ramdisk'
              @in_ramdisk = true
            when 'launchPermission'
              @in_launchPermission= true
              unless @response.key?('launchPermission')
                @response['launchPermission'] = []
              end
            when 'productCodes'
              @in_productCodes = true
              @product_codes = {}
              unless @response.key?('productCodes')
                @response['productCodes'] = []
              end
            when 'blockDeviceMapping'
              @in_blockDeviceMapping = true
              @block_device_mapping = {}
              unless @response.key?('blockDeviceMapping')
                @response['blockDeviceMapping'] = []
              end
            when 'sriovNetSupport'
              unless @response.key?('sriovNetSupport')
                @response['sriovNetSupport'] = 'false'
              end
              @in_sriovNetSupport = true
            end
          end

          def end_element(name)
            if @in_description
              case name
              when 'value'
                @response['description'] = value
              when 'description'
                @in_description= false
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
            elsif @in_launchPermission
              case name
              when 'group', 'userId'
                @response['launchPermission'] << value
              when 'launchPermission'
                @in_launchPermission = false
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
              case name
              when 'item'
                @response['productCodes'] << @product_codes
                @product_codes = {}
              when 'productCode', 'type'
                @product_codes[name] = value
              when 'productCodes'
                @in_productCodes = false
              end
            elsif @in_sriovNetSupport
              case name
              when 'value'
                @response["sriovNetSupport"] = value
              when "sriovNetSupport"
                @in_sriovNetSupport = false
              end
            else
              case name
              when 'requestId', 'imageId'
                @response[name] = value
              end
            end
          end
        end
      end
    end
  end
end
