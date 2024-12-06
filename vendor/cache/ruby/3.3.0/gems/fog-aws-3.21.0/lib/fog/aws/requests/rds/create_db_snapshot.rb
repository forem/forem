module Fog
  module AWS
    class RDS
      class Real
        require 'fog/aws/parsers/rds/create_db_snapshot'

        # creates a db snapshot
        # http://docs.amazonwebservices.com/AmazonRDS/latest/APIReference/API_CreateDBSnapshot.html
        # ==== Parameters
        # * DBInstanceIdentifier <~String> - ID of instance to create snapshot for
        # * DBSnapshotIdentifier <~String> - The identifier for the DB Snapshot. 1-255 alphanumeric or hyphen characters. Must start with a letter
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        def create_db_snapshot(identifier, name)
          request({
            'Action'  => 'CreateDBSnapshot',
            'DBInstanceIdentifier' => identifier,
            'DBSnapshotIdentifier' => name,
            :parser   => Fog::Parsers::AWS::RDS::CreateDBSnapshot.new
          })
        end
      end

      class Mock
        def create_db_snapshot(identifier, name)
          response = Excon::Response.new
          if data[:snapshots][name]
            raise Fog::AWS::RDS::IdentifierTaken.new
          end

          server_data = data[:servers][identifier]

          unless server_data
            raise Fog::AWS::RDS::NotFound.new("DBInstance #{identifier} not found")
          end

          # TODO: raise an error if the server isn't in 'available' state

          snapshot_data = {
            'Status'               => 'creating',
            'SnapshotType'         => 'manual',
            'DBInstanceIdentifier' => identifier,
            'DBSnapshotIdentifier' => name,
            'InstanceCreateTime'   => Time.now
          }
          # Copy attributes from server
          %w(Engine EngineVersion AvailabilityZone AllocatedStorage Iops MasterUsername InstanceCreateTime StorageType).each do |key|
            snapshot_data[key] = server_data[key]
          end
          snapshot_data['Port'] = server_data['Endpoint']['Port']

          self.data[:snapshots][name] = snapshot_data

          # TODO: put the server in 'modifying' state

          response.body = {
            "ResponseMetadata"=>{ "RequestId"=> Fog::AWS::Mock.request_id },
            "CreateDBSnapshotResult"=> {"DBSnapshot"=> snapshot_data.dup}
          }
          response.status = 200
          # SnapshotCreateTime is not part of the response.
          self.data[:snapshots][name]['SnapshotCreateTime'] = Time.now
          response
        end
      end
    end
  end
end
