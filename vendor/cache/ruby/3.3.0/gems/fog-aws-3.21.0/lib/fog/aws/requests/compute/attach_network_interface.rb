module Fog
  module AWS
    class Compute
      class Real
        require 'fog/aws/parsers/compute/attach_network_interface'

        # Attach a network interface
        #
        # ==== Parameters
        # * networkInterfaceId<~String> - ID of the network interface to attach
        # * instanceId<~String>         - ID of the instance that will be attached to the network interface
        # * deviceIndex<~Integer>       - index of the device for the network interface attachment on the instance
        #
        # === Returns
        # * response<~Excon::Response>:
        # * body<~Hash>:
        # * 'requestId'<~String>    - Id of request
        # * 'attachmentId'<~String> - ID of the attachment
        #
        # {Amazon API Reference}[http://docs.amazonwebservices.com/AWSEC2/2012-03-01/APIReference/index.html?ApiReference-query-AttachNetworkInterface.html]
        def attach_network_interface(nic_id, instance_id, device_index)
          request(
            'Action' => 'AttachNetworkInterface',
            'NetworkInterfaceId' => nic_id,
            'InstanceId'         => instance_id,
            'DeviceIndex'        => device_index,
            :parser => Fog::Parsers::AWS::Compute::AttachNetworkInterface.new
          )
        end
      end

      class Mock
        def attach_network_interface(nic_id, instance_id, device_index)
          response = Excon::Response.new
          if ! self.data[:instances].find{ |i,i_conf|
            i_conf['instanceId'] == instance_id
          }
            raise Fog::AWS::Compute::NotFound.new("The instance ID '#{instance_id}' does not exist")
          elsif self.data[:network_interfaces].find{ |ni,ni_conf| ni_conf['attachment']['instanceId'] == instance_id && ni_conf['attachment']['deviceIndex'] == device_index }
            raise Fog::AWS::Compute::Error.new("InvalidParameterValue => Instance '#{instance_id}' already has an interface attached at device index '#{device_index}'.")
          elsif self.data[:network_interfaces][nic_id]
            attachment = self.data[:network_interfaces][nic_id]['attachment']
            attachment['attachmentId'] = Fog::AWS::Mock.request_id
            attachment['instanceId']   = instance_id
            attachment['deviceIndex']  = device_index

            response.status = 200
            response.body = {
              'requestId'    => Fog::AWS::Mock.request_id,
              'attachmentId' => attachment['attachmentId']
            }
          else
            raise Fog::AWS::Compute::NotFound.new("The network interface '#{nic_id}' does not exist")
          end

          response
        end
      end
    end
  end
end
