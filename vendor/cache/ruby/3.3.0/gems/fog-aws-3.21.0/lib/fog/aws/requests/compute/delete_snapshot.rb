module Fog
  module AWS
    class Compute
      class Real
        require 'fog/aws/parsers/compute/basic'

        # Delete a snapshot of an EBS volume that you own
        #
        # ==== Parameters
        # * snapshot_id<~String> - ID of snapshot to delete
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'requestId'<~String> - Id of request
        #     * 'return'<~Boolean> - success?
        #
        # {Amazon API Reference}[http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DeleteSnapshot.html]
        def delete_snapshot(snapshot_id)
          request(
            'Action'      => 'DeleteSnapshot',
            'SnapshotId'  => snapshot_id,
            :idempotent   => true,
            :parser       => Fog::Parsers::AWS::Compute::Basic.new
          )
        end
      end

      class Mock
        def delete_snapshot(snapshot_id)
          response = Excon::Response.new
          if snapshot = self.data[:snapshots].delete(snapshot_id)
            response.status = true
            response.body = {
              'requestId' => Fog::AWS::Mock.request_id,
              'return'    => true
            }
            response
          else
            raise Fog::AWS::Compute::NotFound.new("The snapshot '#{snapshot_id}' does not exist.")
          end
        end
      end
    end
  end
end
