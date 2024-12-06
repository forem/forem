module Fog
  module AWS
    class Compute
      class Real
        require 'fog/aws/parsers/compute/describe_volumes'

        # Describe all or specified volumes.
        #
        # ==== Parameters
        # * filters<~Hash> - List of filters to limit results with
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'volumeSet'<~Array>:
        #       * 'availabilityZone'<~String> - Availability zone for volume
        #       * 'createTime'<~Time> - Timestamp for creation
        #       * 'encrypted'<~Boolean> - Indicates whether the volume will be encrypted
        #       * 'iops'<~Integer> - Number of IOPS volume supports
        #       * 'size'<~Integer> - Size in GiBs for volume
        #       * 'snapshotId'<~String> - Snapshot volume was created from, if any
        #       * 'status'<~String> - State of volume
        #       * 'volumeId'<~String> - Reference to volume
        #       * 'volumeType'<~String> - Type of volume
        #       * 'attachmentSet'<~Array>:
        #         * 'attachmentTime'<~Time> - Timestamp for attachment
        #         * 'deleteOnTermination'<~Boolean> - Whether or not to delete volume on instance termination
        #         * 'device'<~String> - How value is exposed to instance
        #         * 'instanceId'<~String> - Reference to attached instance
        #         * 'status'<~String> - Attachment state
        #         * 'volumeId'<~String> - Reference to volume
        #
        # {Amazon API Reference}[http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DescribeVolumes.html]
        def describe_volumes(filters = {})
          unless filters.is_a?(Hash)
            Fog::Logger.deprecation("describe_volumes with #{filters.class} param is deprecated, use describe_volumes('volume-id' => []) instead [light_black](#{caller.first})[/]")
            filters = {'volume-id' => [*filters]}
          end
          params = Fog::AWS.indexed_filters(filters)
          request({
            'Action'    => 'DescribeVolumes',
            :idempotent => true,
            :parser     => Fog::Parsers::AWS::Compute::DescribeVolumes.new
          }.merge!(params))
        end
      end

      class Mock
        def describe_volumes(filters = {})
          unless filters.is_a?(Hash)
            Fog::Logger.deprecation("describe_volumes with #{filters.class} param is deprecated, use describe_volumes('volume-id' => []) instead [light_black](#{caller.first})[/]")
            filters = {'volume-id' => [*filters]}
          end

          response = Excon::Response.new

          volume_set = self.data[:volumes].values
          volume_set = apply_tag_filters(volume_set, filters, 'volumeId')

          aliases = {
            'availability-zone' => 'availabilityZone',
            'create-time' => 'createTime',
            'encrypted' => 'encrypted',
            'size' => 'size',
            'snapshot-id' => 'snapshotId',
            'status' => 'status',
            'volume-id' => 'volumeId'
          }
          attachment_aliases = {
            'attach-time' => 'attachTime',
            'delete-on-termination' => 'deleteOnTermination',
            'device'      => 'device',
            'instance-id' => 'instanceId',
            'status'      => 'status'
          }

          for filter_key, filter_value in filters
            if attachment_key = filter_key.split('attachment.')[1]
              aliased_key = attachment_aliases[filter_key]
              volume_set = volume_set.reject{|volume| !volume['attachmentSet'].find {|attachment| [*filter_value].include?(attachment[aliased_key])}}
            else
              aliased_key = aliases[filter_key]
              volume_set = volume_set.reject{|volume| ![*filter_value].include?(volume[aliased_key])}
            end
          end

          volume_set.each do |volume|
            case volume['status']
            when 'attaching'
              if Time.now - volume['attachmentSet'].first['attachTime'] >= Fog::Mock.delay
                volume['attachmentSet'].first['status'] = 'in-use'
                volume['status'] = 'in-use'
              end
            when 'creating'
              if Time.now - volume['createTime'] >= Fog::Mock.delay
                volume['status'] = 'available'
              end
            when 'deleting'
              if Time.now - self.data[:deleted_at][volume['volumeId']] >= Fog::Mock.delay
                self.data[:deleted_at].delete(volume['volumeId'])
                self.data[:volumes].delete(volume['volumeId'])
              end
            end
          end
          volume_set = volume_set.reject {|volume| !self.data[:volumes][volume['volumeId']]}
          volume_set = volume_set.map {|volume| volume.merge('tagSet' => self.data[:tag_sets][volume['volumeId']]) }

          response.status = 200
          response.body = {
            'requestId' => Fog::AWS::Mock.request_id,
            'volumeSet' => volume_set
          }
          response
        end
      end
    end
  end
end
