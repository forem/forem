module Fog
  module AWS
    class Compute
      class Real
        require 'fog/aws/parsers/compute/register_image'

        # register an image
        #
        # ==== Parameters
        # * Name<~String> - Name of the AMI to be registered
        # * Description<~String> - AMI description
        # * Location<~String> - S3 manifest location (for S3 backed AMIs)
        # or
        # * RootDeviceName<~String> - Name of Root Device (for EBS snapshot backed AMIs)
        # * BlockDevices<~Array>:
        #   * BlockDeviceOptions<~Hash>:
        #     * DeviceName<~String> - Name of the Block Device
        #     * VirtualName<~String> - Name of the Virtual Device
        #     * SnapshotId<~String> - id of the EBS Snapshot
        #     * VolumeSize<~Integer> - Size of the snapshot (optional)
        #     * NoDevice<~Boolean> - Do not use an ebs device (def: true)
        #     * DeleteOnTermation<~Boolean> - Delete EBS volume on instance term (def: true)
        # * Options<~Hash>:
        #   * Architecture<~String> - i386 or x86_64
        #   * KernelId<~String> - kernelId
        #   * RamdiskId<~String> - ramdiskId
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'imageId'<~String> - Id of newly created AMI

        #

        # {Amazon API Reference}[http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-RegisterImage.html]

        def register_image(name, description, location, block_devices=[], options={})
          common_options = {
            'Action'      => 'RegisterImage',
            'Name'        => name,
            'Description' => description,
            :parser       => Fog::Parsers::AWS::Compute::RegisterImage.new
          }

          # This determines if we are doing a snapshot or a S3 backed AMI.
          if(location =~ /^\/dev\/(xvd|sd)[a-p]\d{0,2}$/)
            common_options['RootDeviceName'] = location
          else
            common_options['ImageLocation'] = location
          end

          block_devices.each_with_index do |bd, index|
            index += 1
            ["DeviceName","VirtualName"].each do |n|
              common_options["BlockDeviceMapping.#{index}.#{n}"] = bd[n] if bd[n]
            end
            ["SnapshotId","VolumeSize","NoDevice","DeleteOnTermination"].each do |n|
              common_options["BlockDeviceMapping.#{index}.Ebs.#{n}"] = bd[n] if bd[n]
            end
          end

          request(common_options.merge!(options))
        end
      end

      class Mock
        def register_image(name, description, location, block_devices=[], options={})
          unless name.empty?
            image = {
              'imageId' => Fog::AWS::Mock.image_id,
              'imageLocation' => '',
              'imageState' => 'pending',
              'imageOwnerId' => self.data[:owner_id],
              'isPublic' => false,
              'productCodes' => [],
              'architecture' => options['Architecture'] || 'i386',
              'imageType' => 'machine',
              'kernelId' => options['KernelId'] || Fog::AWS::Mock.kernel_id,
              'ramdiskId' => options['RamdiskId'] || Fog::AWS::Mock.ramdisk_id,
              'platform' => 'Linux',
              'stateReason' => {},
              'imageOwnerAlias' => self.data[:owner_id],
              'name' => name,
              'description' => description,
              'rootDeviceType' => '',
              'rootDeviceName' => '',
              'blockDeviceMapping' => [],
              'virtualizationType' => 'paravirtual',
              'hypervisor' => 'xen',
              'registered' => Time.now
            }

            if location[/^\/dev\/(xvd|sd)[a-p]\d{0,2}$/]
              image['rootDeviceName'] = location
              image['rootDeviceType'] = 'ebs'
            else
              image['imageLocation'] = location
            end

            block_devices.each do |bd|
              block_device_mapping = {
                'ebs' => {}
              }
              ["DeviceName","VirtualName"].each do |n|
                block_device_mapping[n] = bd[n] if bd[n]
              end
              ["SnapshotId","VolumeSize","NoDevice","DeleteOnTermination"].each do |n|
                block_device_mapping['ebs'][n] = bd[n] if bd[n]
              end
              image['blockDeviceMapping'] << block_device_mapping
            end

            self.data[:images][image['imageId']] = image

            response = Excon::Response.new
            response.status = 200
            response.body = {
              'requestId' => Fog::AWS::Mock.request_id,
              'imageId' => image['imageId']
            }
            response
          else
            message = 'MissingParameter => '
            if name.empty?
              message << 'The request must contain the parameter name'
            end
            raise Fog::AWS::Compute::Error.new(message)
          end
        end
      end
    end
  end
end
