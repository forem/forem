module Fog
  module AWS
    class Compute
      class Real
        require 'fog/aws/parsers/compute/modify_volume'

        # Modifies a volume
        #
        # ==== Parameters
        # * volume_id<~String> - The ID of the volume
        # * options<~Hash>:
        #   * 'VolumeType'<~String> - Type of volume
        #   * 'Size'<~Integer> - Size in GiBs fo the volume
        #   * 'Iops'<~Integer> - Number of IOPS the volume supports
        #
        # ==== Response
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'targetIops'<~Integer> - Target IOPS rate of the volume being modified.
        #     * 'originalIops'<~Integer> - Original IOPS rate of the volume being modified.
        #     * 'modificationState'<~String> - Current state of modification. Modification state is null for unmodified volumes.
        #     * 'targetSize'<~Integer> - Target size of the volume being modified.
        #     * 'targetVolumeType'<~String> - Target EBS volume type of the volume being modified.
        #     * 'volumeId'<~String> - ID of the volume being modified.
        #     * 'progress'<~Integer> - Modification progress from 0 to 100%.
        #     * 'startTime'<~Time> - Modification start time
        #     * 'endTime'<~Time> - Modification end time
        #     * 'originalSize'<~Integer> - Original size of the volume being modified.
        #     * 'originalVolumeType'<~String> - Original EBS volume type of the volume being modified.

        def modify_volume(volume_id, options={})
          request({
            'Action'   => "ModifyVolume",
            'VolumeId' => volume_id,
            :parser    => Fog::Parsers::AWS::Compute::ModifyVolume.new
          }.merge(options))
        end
      end

      class Mock
        def modify_volume(volume_id, options={})
          response = Excon::Response.new
          volume   = self.data[:volumes][volume_id]

          if volume["volumeType"] == 'standard' && options['VolumeType']
            raise Fog::AWS::Compute::Error.new("InvalidParameterValue => Volume type EBS Magnetic is not supported.")
          end

          volume_modification = {
            'modificationState' => 'modifying',
            'progress'          => 0,
            'startTime'         => Time.now,
            'volumeId'          => volume_id
          }

          if options['Size']
            volume_modification.merge!(
              'originalSize' => volume['size'],
              'targetSize'   => options['Size']
            )
          end

          if options['Iops']
            volume_modification.merge!(
              'originalIops' => volume['iops'],
              'targetIops'   => options['Iops']
            )
          end

          if options['VolumeType']
            if options["VolumeType"] == 'standard'
              raise Fog::AWS::Compute::Error.new("InvalidParameterValue => Volume type EBS Magnetic is not supported.")
            end
            volume_modification.merge!(
              'originalVolumeType' => volume['volumeType'],
              'targetVolumeType'   => options['VolumeType']
            )
          end

          self.data[:volume_modifications][volume_id] = volume_modification

          response.body = {'volumeModification' => volume_modification, 'requestId' => Fog::AWS::Mock.request_id}
          response
        end
      end
    end
  end
end
