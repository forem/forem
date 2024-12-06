module Fog
  module AWS
    class Compute
      class Real
        require 'fog/aws/parsers/compute/describe_snapshots'

        # Describe all or specified snapshots
        #
        # ==== Parameters
        # * filters<~Hash> - List of filters to limit results with
        # * options<~Hash>:
        #   * 'Owner'<~String> - Owner of snapshot in ['self', 'amazon', account_id]
        #   * 'RestorableBy'<~String> - Account id of user who can create volumes from this snapshot
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'requestId'<~String> - Id of request
        #     * 'snapshotSet'<~Array>:
        #       * 'encrypted'<~Boolean>: The encryption status of the snapshot.
        #       * 'progress'<~String>: The percentage progress of the snapshot
        #       * 'snapshotId'<~String>: Id of the snapshot
        #       * 'startTime'<~Time>: Timestamp of when snapshot was initiated
        #       * 'status'<~String>: Snapshot state, in ['pending', 'completed']
        #       * 'volumeId'<~String>: Id of volume that snapshot contains
        #
        # {Amazon API Reference}[http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DescribeSnapshots.html]
        def describe_snapshots(filters = {}, options = {})
          unless filters.is_a?(Hash)
            Fog::Logger.deprecation("describe_snapshots with #{filters.class} param is deprecated, use describe_snapshots('snapshot-id' => []) instead [light_black](#{caller.first})[/]")
            filters = {'snapshot-id' => [*filters]}
          end
          unless options.empty?
            Fog::Logger.deprecation("describe_snapshots with a second param is deprecated, use describe_snapshots(options) instead [light_black](#{caller.first})[/]")
          end

          for key in ['ExecutableBy', 'ImageId', 'Owner', 'RestorableBy']
            if filters.key?(key)
              options[key] = filters.delete(key)
            end
          end
          options['RestorableBy'] ||= 'self'
          params = Fog::AWS.indexed_filters(filters).merge!(options)
          request({
            'Action'    => 'DescribeSnapshots',
            :idempotent => true,
            :parser     => Fog::Parsers::AWS::Compute::DescribeSnapshots.new
          }.merge!(params))
        end
      end

      class Mock
        def describe_snapshots(filters = {}, options = {})
          unless filters.is_a?(Hash)
            Fog::Logger.deprecation("describe_snapshots with #{filters.class} param is deprecated, use describe_snapshots('snapshot-id' => []) instead [light_black](#{caller.first})[/]")
            filters = {'snapshot-id' => [*filters]}
          end
          unless options.empty?
            Fog::Logger.deprecation("describe_snapshots with a second param is deprecated, use describe_snapshots(options) instead [light_black](#{caller.first})[/]")
          end

          response = Excon::Response.new

          snapshot_set = self.data[:snapshots].values

          if filters.delete('owner-alias')
            Fog::Logger.warning("describe_snapshots with owner-alias is not mocked [light_black](#{caller.first})[/]")
          end
          if (restorable_by = filters.delete('RestorableBy')) && restorable_by != 'self'
            Fog::Logger.warning("describe_snapshots with RestorableBy other than 'self' (wanted #{restorable_by.inspect}) is not mocked [light_black](#{caller.first})[/]")
          end

          snapshot_set = apply_tag_filters(snapshot_set, filters, 'snapshotId')

          aliases = {
            'description' => 'description',
            'encrypted'   => 'encrypted',
            'owner-id'    => 'ownerId',
            'progress'    => 'progress',
            'snapshot-id' => 'snapshotId',
            'start-time'  => 'startTime',
            'status'      => 'status',
            'volume-id'   => 'volumeId',
            'volume-size' => 'volumeSize'
          }

          for filter_key, filter_value in filters
            aliased_key = aliases[filter_key]
            snapshot_set = snapshot_set.reject{|snapshot| ![*filter_value].include?(snapshot[aliased_key])}
          end

          snapshot_set.each do |snapshot|
            case snapshot['status']
            when 'in progress', 'pending'
              if Time.now - snapshot['startTime'] >= Fog::Mock.delay * 2
                snapshot['progress']  = '100%'
                snapshot['status']    = 'completed'
              elsif Time.now - snapshot['startTime'] >= Fog::Mock.delay
                snapshot['progress']  = '50%'
                snapshot['status']    = 'in progress'
              else
                snapshot['progress']  = '0%'
                snapshot['status']    = 'in progress'
              end
            end
          end

          snapshot_set = snapshot_set.map {|snapshot| snapshot.merge('tagSet' => self.data[:tag_sets][snapshot['snapshotId']]) }

          response.status = 200
          response.body = {
            'requestId' => Fog::AWS::Mock.request_id,
            'snapshotSet' => snapshot_set
          }
          response
        end
      end
    end
  end
end
