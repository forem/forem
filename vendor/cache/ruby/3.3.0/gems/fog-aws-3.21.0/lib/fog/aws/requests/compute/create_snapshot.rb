module Fog
  module AWS
    class Compute
      class Real
        require 'fog/aws/parsers/compute/create_snapshot'

        # Create a snapshot of an EBS volume and store it in S3
        #
        # ==== Parameters
        # * volume_id<~String> - Id of EBS volume to snapshot
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'encrypted'<~Boolean>: The encryption status of the snapshot.
        #     * 'progress'<~String> - The percentage progress of the snapshot
        #     * 'requestId'<~String> - id of request
        #     * 'snapshotId'<~String> - id of snapshot
        #     * 'startTime'<~Time> - timestamp when snapshot was initiated
        #     * 'status'<~String> - state of snapshot
        #     * 'volumeId'<~String> - id of volume snapshot targets
        #
        # {Amazon API Reference}[http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-CreateSnapshot.html]
        def create_snapshot(volume_id, description = nil)
          request(
            'Action'      => 'CreateSnapshot',
            'Description' => description,
            'VolumeId'    => volume_id,
            :parser       => Fog::Parsers::AWS::Compute::CreateSnapshot.new
          )
        end
      end

      class Mock
        #
        # Usage
        #
        # Fog::AWS[:compute].create_snapshot("vol-f7c23423", "latest snapshot")
        #

        def create_snapshot(volume_id, description = nil)
          response = Excon::Response.new
          if volume = self.data[:volumes][volume_id]
            response.status = 200
            snapshot_id = Fog::AWS::Mock.snapshot_id
            data = {
              'description' => description,
              'encrypted'   => false,
              'ownerId'     => self.data[:owner_id],
              'progress'    => nil,
              'snapshotId'  => snapshot_id,
              'startTime'   => Time.now,
              'status'      => 'pending',
              'volumeId'    => volume_id,
              'volumeSize'  => volume['size']
            }
            self.data[:snapshots][snapshot_id] = data
            response.body = {
              'requestId' => Fog::AWS::Mock.request_id
            }.merge!(data)
          else
            response.status = 400
            raise(Excon::Errors.status_error({:expects => 200}, response))
          end
          response
        end
      end
    end
  end
end
