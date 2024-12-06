module Fog
  module AWS
    class RDS
      class Real
        require 'fog/aws/parsers/rds/delete_db_cluster_snapshot'

        # delete a db cluster snapshot
        # http://docs.aws.amazon.com/AmazonRDS/latest/APIReference/API_DeleteDBClusterSnapshot.html
        #
        # ==== Parameters ====
        # * DBClusterSnapshotIdentifier<~String> - The identifier of the DB cluster snapshot to delete
        #
        # ==== Returns ====
        # * response<~Excon::Response>:
        #   * body<~Hash>:

        def delete_db_cluster_snapshot(name)
          request(
            'Action'                      => 'DeleteDBClusterSnapshot',
            'DBClusterSnapshotIdentifier' => name,
            :parser                       => Fog::Parsers::AWS::RDS::DeleteDBClusterSnapshot.new
          )
        end
      end

      class Mock
        def delete_db_cluster_snapshot(name)
          response = Excon::Response.new
          snapshot = self.data[:cluster_snapshots].delete(name)

          raise Fog::AWS::RDS::NotFound.new("DBClusterSnapshotNotFound => #{name} not found") unless snapshot

          response.status = 200
          response.body = {
            "ResponseMetadata"              => {"RequestId"         => Fog::AWS::Mock.request_id},
            "DeleteDBClusterSnapshotResult" => {"DBClusterSnapshot" => snapshot}
          }
          response
        end
      end
    end
  end
end
