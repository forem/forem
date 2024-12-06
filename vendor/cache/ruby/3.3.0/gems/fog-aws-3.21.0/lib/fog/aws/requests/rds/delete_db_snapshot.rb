module Fog
  module AWS
    class RDS
      class Real
        require 'fog/aws/parsers/rds/delete_db_snapshot'

        # delete a database snapshot
        # http://docs.amazonwebservices.com/AmazonRDS/latest/APIReference/API_DeleteDBSnapshot.html
        # ==== Parameters
        # * DBSnapshotIdentifier <~String> - name of the snapshot
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        def delete_db_snapshot(name)
          request({
            'Action'  => 'DeleteDBSnapshot',
            'DBSnapshotIdentifier' => name,

            :parser   => Fog::Parsers::AWS::RDS::DeleteDBSnapshot.new
          })
        end
      end

      class Mock
        def delete_db_snapshot(name)
          # TODO: raise error if snapshot isn't 'available'
          response = Excon::Response.new
          snapshot_data = self.data[:snapshots].delete(name)
          snapshot_data = self.data[:cluster_snapshots].delete(name) unless snapshot_data

          raise Fog::AWS::RDS::NotFound.new("DBSnapshotNotFound => #{name} not found") unless snapshot_data

          response.status = 200
          response.body = {
            "ResponseMetadata"=> { "RequestId"=> Fog::AWS::Mock.request_id },
            "DeleteDBSnapshotResult"=> {"DBSnapshot"=> snapshot_data}
          }
          response
        end
      end
    end
  end
end
