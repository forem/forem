module Fog
  module AWS
    class Compute
      class Real
        require 'fog/aws/parsers/compute/attach_volume'

        # Attach an Amazon EBS volume with a running instance, exposing as specified device
        #
        # ==== Parameters
        # * instance_id<~String> - Id of instance to associate volume with
        # * volume_id<~String> - Id of amazon EBS volume to associate with instance
        # * device<~String> - Specifies how the device is exposed to the instance (e.g. "/dev/sdh")
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'attachTime'<~Time> - Time of attachment was initiated at
        #     * 'device'<~String> - Device as it is exposed to the instance
        #     * 'instanceId'<~String> - Id of instance for volume
        #     * 'requestId'<~String> - Id of request
        #     * 'status'<~String> - Status of volume
        #     * 'volumeId'<~String> - Reference to volume
        #
        # {Amazon API Reference}[http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-AttachVolume.html]
        def attach_volume(instance_id, volume_id, device)
          request(
            'Action'      => 'AttachVolume',
            'VolumeId'    => volume_id,
            'InstanceId'  => instance_id,
            'Device'      => device,
            :idempotent   => true,
            :parser       => Fog::Parsers::AWS::Compute::AttachVolume.new
          )
        end
      end

      class Mock
        def attach_volume(instance_id, volume_id, device)
          response = Excon::Response.new
          if instance_id && volume_id && device
            response.status = 200
            instance = self.data[:instances][instance_id]
            volume = self.data[:volumes][volume_id]
            if instance && volume
              unless volume['status'] == 'available'
                raise Fog::AWS::Compute::Error.new("Client.VolumeInUse => Volume #{volume_id} is unavailable")
              end

              data = {
                'attachTime'  => Time.now,
                'device'      => device,
                'instanceId'  => instance_id,
                'status'      => 'attaching',
                'volumeId'    => volume_id
              }
              volume['attachmentSet'] = [data]
              volume['status'] = 'attaching'
              response.status = 200
              response.body = {
                'requestId' => Fog::AWS::Mock.request_id
              }.merge!(data)
              response
            elsif !instance
              raise Fog::AWS::Compute::NotFound.new("The instance ID '#{instance_id}' does not exist.")
            elsif !volume
              raise Fog::AWS::Compute::NotFound.new("The volume '#{volume_id}' does not exist.")
            end
          else
            message = 'MissingParameter => '
            if !instance_id
              message << 'The request must contain the parameter instance_id'
            elsif !volume_id
              message << 'The request must contain the parameter volume_id'
            else
              message << 'The request must contain the parameter device'
            end
            raise Fog::AWS::Compute::Error.new(message)
          end
        end
      end
    end
  end
end
