module Fog
  module AWS
    class RDS
      class Real
        require 'fog/aws/parsers/rds/delete_db_instance'

        # delete a database instance
        # http://docs.amazonwebservices.com/AmazonRDS/latest/APIReference/API_DeleteDBInstance.html
        # ==== Parameters
        # * DBInstanceIdentifier <~String> - The DB Instance identifier for the DB Instance to be deleted.
        # * FinalDBSnapshotIdentifier <~String> - The DBSnapshotIdentifier of the new DBSnapshot created when SkipFinalSnapshot is set to false
        # * SkipFinalSnapshot <~Boolean> - Determines whether a final DB Snapshot is created before the DB Instance is deleted
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        def delete_db_instance(identifier, snapshot_identifier, skip_snapshot = false)
          params = {}
          params['FinalDBSnapshotIdentifier'] = snapshot_identifier if snapshot_identifier
          request({
            'Action'               => 'DeleteDBInstance',
            'DBInstanceIdentifier' => identifier,
            'SkipFinalSnapshot'    => skip_snapshot,
            :parser                => Fog::Parsers::AWS::RDS::DeleteDBInstance.new
          }.merge(params))
        end
      end

      class Mock
        def delete_db_instance(identifier, snapshot_identifier, skip_snapshot = false)
          response = Excon::Response.new


          server_set = self.data[:servers][identifier] ||
            raise(Fog::AWS::RDS::NotFound.new("DBInstance #{identifier} not found"))

          unless skip_snapshot
            if server_set["ReadReplicaSourceDBInstanceIdentifier"]
              raise Fog::AWS::RDS::Error.new("InvalidParameterCombination => FinalDBSnapshotIdentifier can not be specified when deleting a replica instance")
            elsif server_set["DBClusterIdentifier"] && snapshot_identifier # for cluster instances, you must pass in skip_snapshot = false, but not specify a snapshot identifier
              raise Fog::AWS::RDS::Error.new("InvalidParameterCombination => FinalDBSnapshotIdentifier can not be specified when deleting a cluster instance")
            elsif server_set["DBClusterIdentifier"] && !snapshot_identifier && !skip_snapshot
              #no-op
            else
              create_db_snapshot(identifier, snapshot_identifier)
            end
          end

          cluster = self.data[:clusters].values.detect { |c| c["DBClusterMembers"].any? { |m| m["DBInstanceIdentifier"] == identifier } }

          if cluster
            cluster["DBClusterMembers"].delete_if { |v| v["DBInstanceIdentifier"] == identifier }
            self.data[:clusters][cluster["DBClusterIdentifier"]] = cluster
          end

          self.data[:servers].delete(identifier)

          response.status = 200
          response.body = {
            "ResponseMetadata"       => { "RequestId"  => Fog::AWS::Mock.request_id },
            "DeleteDBInstanceResult" => { "DBInstance" => server_set }
          }
          response
        end
      end
    end
  end
end
