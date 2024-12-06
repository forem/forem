module Fog
  module AWS
    class Compute
      class Real
        require 'fog/aws/parsers/compute/create_image'

        # Create a bootable EBS volume AMI
        #
        # ==== Parameters
        # * instance_id<~String> - Instance used to create image.
        # * name<~Name> - Name to give image.
        # * description<~Name> - Description of image.
        # * no_reboot<~Boolean> - Optional, whether or not to reboot the image when making the snapshot
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'imageId'<~String> - The ID of the created AMI.
        #     * 'requestId'<~String> - Id of request.
        #
        # {Amazon API Reference}[http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-CreateImage.html]
        def create_image(instance_id, name, description, no_reboot = false, options={})
          params = {}
          block_device_mappings = options[:block_device_mappings] ||  []

          params.merge!Fog::AWS.indexed_param('BlockDeviceMapping.%d.DeviceName', block_device_mappings.map{|mapping| mapping['DeviceName']})
          params.merge!Fog::AWS.indexed_param('BlockDeviceMapping.%d.NoDevice', block_device_mappings.map{|mapping| mapping['NoDevice']})
          params.merge!Fog::AWS.indexed_param('BlockDeviceMapping.%d.VirtualName', block_device_mappings.map{|mapping| mapping['VirtualName']})
          params.merge!Fog::AWS.indexed_param('BlockDeviceMapping.%d.Ebs.SnapshotId', block_device_mappings.map{|mapping| mapping['Ebs.SnapshotId']})
          params.merge!Fog::AWS.indexed_param('BlockDeviceMapping.%d.Ebs.DeleteOnTermination', block_device_mappings.map{|mapping| mapping['Ebs.DeleteOnTermination']})
          params.merge!Fog::AWS.indexed_param('BlockDeviceMapping.%d.Ebs.VolumeType', block_device_mappings.map{|mapping| mapping['Ebs.VolumeType']})
          params.merge!Fog::AWS.indexed_param('BlockDeviceMapping.%d.Ebs.Encrypted', block_device_mappings.map{|mapping| mapping['Ebs.Encrypted']})
          params.merge!Fog::AWS.indexed_param('BlockDeviceMapping.%d.Ebs.Iops', block_device_mappings.map{|mapping| mapping['Ebs.Iops']})
          params.reject!{|k,v| v.nil?}

          request({
            'Action'            => 'CreateImage',
            'InstanceId'        => instance_id,
            'Name'              => name,
            'Description'       => description,
            'NoReboot'          => no_reboot.to_s,
            :parser             => Fog::Parsers::AWS::Compute::CreateImage.new
          }.merge!(params))
        end
      end

      class Mock
        # Usage
        #
        # Fog::AWS[:compute].create_image("i-ac65ee8c", "test", "something")
        #

        def create_image(instance_id, name, description, no_reboot = false, options = {})
          params = {}
          block_device_mappings = options[:block_device_mappings] || []
          params.merge!Fog::AWS.indexed_param('BlockDeviceMapping.%d.DeviceName', block_device_mappings.map{|mapping| mapping['DeviceName']})
          params.merge!Fog::AWS.indexed_param('BlockDeviceMapping.%d.NoDevice', block_device_mappings.map{|mapping| mapping['NoDevice']})
          params.merge!Fog::AWS.indexed_param('BlockDeviceMapping.%d.VirtualName', block_device_mappings.map{|mapping| mapping['VirtualName']})
          params.merge!Fog::AWS.indexed_param('BlockDeviceMapping.%d.Ebs.SnapshotId', block_device_mappings.map{|mapping| mapping['Ebs.SnapshotId']})
          params.merge!Fog::AWS.indexed_param('BlockDeviceMapping.%d.Ebs.DeleteOnTermination', block_device_mappings.map{|mapping| mapping['Ebs.DeleteOnTermination']})
          params.merge!Fog::AWS.indexed_param('BlockDeviceMapping.%d.Ebs.VolumeType', block_device_mappings.map{|mapping| mapping['Ebs.VolumeType']})
          params.merge!Fog::AWS.indexed_param('BlockDeviceMapping.%d.Ebs.Encrypted', block_device_mappings.map{|mapping| mapping['Ebs.Encrypted']})
          params.merge!Fog::AWS.indexed_param('BlockDeviceMapping.%d.Ebs.Iops', block_device_mappings.map{|mapping| mapping['Ebs.Iops']})
          params.reject!{|k,v| v.nil?}

          reserved_ebs_root_device  = '/dev/sda1'
          block_devices = options.delete(:block_device_mappings) || []
          register_image_response = register_image(name, description, reserved_ebs_root_device, block_devices, options)

          response = Excon::Response.new
          if instance_id && !name.empty?
            response.status = 200
            response.body = {
              'requestId' => Fog::AWS::Mock.request_id,
              'imageId' => register_image_response.body['imageId']
            }
          else
            response.status = 400
            response.body = {
              'Code' => 'InvalidParameterValue'
            }
            if name.empty?
              response.body['Message'] = "Invalid value '' for name. Must be specified."
            end
          end
          response
        end
      end
    end
  end
end
