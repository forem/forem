module Fog
  module AWS
    class Compute
      class Real
        require 'fog/aws/parsers/compute/basic'

        # Modifies a volume attribute.
        #
        # ==== Parameters
        # * volume_id<~String> - The ID of the volume.
        # * auto_enable_io_value<~Boolean> - This attribute exists to auto-enable the I/O operations to the volume.
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'requestId'<~String> - Id of request
        #     * 'return'<~Boolean> - success?
        #
        # {Amazon API Reference}[http://http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-ModifyVolumeAttribute.html]
        def modify_volume_attribute(volume_id=nil, auto_enable_io_value=false)
          request(
            'Action'             => 'ModifyVolumeAttribute',
            'VolumeId'           => volume_id,
            'AutoEnableIO.Value' => auto_enable_io_value,
            :idempotent          => true,
            :parser              => Fog::Parsers::AWS::Compute::Basic.new
          )
        end
      end

      class Mock
        def modify_volume_attribute(volume_id=nil, auto_enable_io_value=false)
          response = Excon::Response.new
          if volume = self.data[:volumes][volume_id]
            response.status = 200
            response.body = {
              'requestId' => Fog::AWS::Mock.request_id,
              'return'    => true
            }
            response
          else
            raise Fog::AWS::Compute::NotFound.new("The volume '#{volume_id}' does not exist.")
          end
        end
      end
    end
  end
end
