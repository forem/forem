module Fog
  module AWS
    class RDS
      class Real
        require 'fog/aws/parsers/rds/create_db_cluster_snapshot'

        # create a snapshot of a db cluster
        # http://docs.aws.amazon.com/AmazonRDS/latest/APIReference/API_CreateDBClusterSnapshot.html
        #
        # ==== Parameters ====
        # * DBClusterIdentifier<~String> - The identifier of the DB cluster to create a snapshot for
        # * DBClusterSnapshotIdentifier<~String> - The identifier of the DB cluster snapshot
        # * Tags<~Array> - The tags to be assigned to the DB cluster snapshot
        #
        # ==== Returns ====
        # * response<~Excon::Response>:
        #   * body<~Hash>:

        def create_db_cluster_snapshot(identifier, name)
          request(
            'Action'                      => 'CreateDBClusterSnapshot',
            'DBClusterIdentifier'         => identifier,
            'DBClusterSnapshotIdentifier' => name,
            :parser                       => Fog::Parsers::AWS::RDS::CreateDBClusterSnapshot.new
          )
        end
      end

      class Mock
        def create_db_cluster_snapshot(identifier, name)
          response = Excon::Response.new

          if data[:cluster_snapshots][name]
            raise Fog::AWS::RDS::IdentifierTaken.new
          end

          cluster = self.data[:clusters][identifier]

          raise Fog::AWS::RDS::NotFound.new("DBCluster #{identifier} not found") unless cluster

          data = {
            'AllocatedStorage'            => cluster['AllocatedStorage'].to_i,
            'ClusterCreateTime'           => cluster['ClusterCreateTime'],
            'DBClusterIdentifier'         => identifier,
            'DBClusterSnapshotIdentifier' => name,
            'Engine'                      => cluster['Engine'],
            'EngineVersion'               => cluster['EngineVersion'],
            'LicenseModel'                => cluster['Engine'],
            'MasterUsername'              => cluster['MasterUsername'],
            'SnapshotCreateTime'          => Time.now,
            'SnapshotType'                => 'manual',
            'StorageEncrypted'            => cluster["StorageEncrypted"],
            'Status'                      => 'creating',
          }

          self.data[:cluster_snapshots][name] = data

          response.body = {
            "ResponseMetadata"              => { "RequestId" => Fog::AWS::Mock.request_id },
            "CreateDBClusterSnapshotResult" => { "DBClusterSnapshot" => data.dup },
          }
          self.data[:cluster_snapshots][name]['SnapshotCreateTime'] = Time.now
          response
        end
      end
    end
  end
end
