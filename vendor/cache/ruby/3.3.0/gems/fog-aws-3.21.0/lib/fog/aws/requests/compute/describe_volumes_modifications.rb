module Fog
  module AWS
    class Compute
      class Real
        require 'fog/aws/parsers/compute/describe_volumes_modifications'

        # Reports the current modification status of EBS volumes.
        #
        # ==== Parameters
        # * filters<~Hash> - List of filters to limit results with
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>
        #     * 'volumeModificationSet'<~Array>:
        #       * 'targetIops'<~Integer> - Target IOPS rate of the volume being modified.
        #       * 'originalIops'<~Integer> - Original IOPS rate of the volume being modified.
        #       * 'modificationState'<~String> - Current state of modification. Modification state is null for unmodified volumes.
        #       * 'targetSize'<~Integer> - Target size of the volume being modified.
        #       * 'targetVolumeType'<~String> - Target EBS volume type of the volume being modified.
        #       * 'volumeId'<~String> - ID of the volume being modified.
        #       * 'progress'<~Integer> - Modification progress from 0 to 100%.
        #       * 'startTime'<~Time> - Modification start time
        #       * 'endTime'<~Time> - Modification end time
        #       * 'originalSize'<~Integer> - Original size of the volume being modified.
        #       * 'originalVolumeType'<~String> - Original EBS volume type of the volume being modified.

        def describe_volumes_modifications(filters = {})
          params = {}
          if volume_id = filters.delete('volume-id')
            params.merge!(Fog::AWS.indexed_param('VolumeId.%d', [*volume_id]))
          end
          params.merge!(Fog::AWS.indexed_filters(filters))
          request({
            'Action'    => 'DescribeVolumesModifications',
            :idempotent => true,
            :parser     => Fog::Parsers::AWS::Compute::DescribeVolumesModifications.new
          }.merge(params))
        end
      end

      class Mock
        def describe_volumes_modifications(filters = {})
          response = Excon::Response.new

          modification_set = self.data[:volume_modifications].values

          aliases = {
            'volume-id'            => 'volumeId',
            'modification-state'   => 'modificationState',
            'target-size'          => 'targetSize',
            'target-iops'          => 'targetIops',
            'target-volume-type'   => 'targetVolumeType',
            'original-size'        => 'originalSize',
            'original-iops'        => 'originalIops',
            'original-volume-type' => 'originalVolumeType',
            'start-time'           => 'startTime'
          }

          attribute_aliases = {
            'targetSize'       => 'size',
            'targetVolumeType' => 'volumeType',
            'targetIops'       => 'iops'
          }

          for filter_key, filter_value in filters
            aliased_key = aliases[filter_key]
            modification_set = modification_set.reject { |m| ![*filter_value].include?(m[aliased_key]) }
          end

          modification_set.each do |modification|
            case modification['modificationState']
            when 'modifying'
              volume = self.data[:volumes][modification['volumeId']]
              modification['modificationState'] = 'optimizing'
              %w(targetSize targetIops targetVolumeType).each do |attribute|
                aliased_attribute = attribute_aliases[attribute]
                volume[aliased_attribute] = modification[attribute] if modification[attribute]
              end
              self.data[:volumes][modification['volumeId']] = volume
            when 'optimizing'
              modification['modificationState'] = 'completed'
              modification['endTime']           = Time.now
            end
          end

          response.body = {'requestId' => Fog::AWS::Mock.request_id, 'volumeModificationSet' => modification_set}
          response
        end
      end
    end
  end
end
