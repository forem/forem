module Fog
  module AWS
    class RDS
      class Real
        require 'fog/aws/parsers/rds/copy_db_snapshot'

        # Copy a db snapshot
        #
        # ==== Parameters
        # * source_db_snapshot_identifier<~String> - Id of db snapshot
        # * target_db_snapshot_identifier<~String> - Desired Id of the db snapshot copy
        # * 'copy_tags'<~Boolean> - true to copy all tags from the source DB snapshot to the target DB snapshot; otherwise false.
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #
        # {Amazon API Reference}[http://docs.aws.amazon.com/AmazonRDS/latest/APIReference/API_CopyDBSnapshot.html]
        def copy_db_snapshot(source_db_snapshot_identifier, target_db_snapshot_identifier, copy_tags = false)
          request(
            'Action'                     => 'CopyDBSnapshot',
            'SourceDBSnapshotIdentifier' => source_db_snapshot_identifier,
            'TargetDBSnapshotIdentifier' => target_db_snapshot_identifier,
            'CopyTags'                   => copy_tags,
            :parser                      => Fog::Parsers::AWS::RDS::CopyDBSnapshot.new
          )
        end
      end

      class Mock
        #
        # Usage
        #
        # Fog::AWS[:rds].copy_db_snapshot("snap-original-id", "snap-backup-id", true)
        #

        def copy_db_snapshot(source_db_snapshot_identifier, target_db_snapshot_identifier, copy_tags = false)
          response = Excon::Response.new
          response.status = 200
          snapshot_id =  Fog::AWS::Mock.snapshot_id
          data = self.data[:snapshots]["#{source_db_snapshot_identifier}"]
          data['DBSnapshotIdentifier'] = snapshot_id
          self.data[:snapshots][snapshot_id] = data
          response.body = {
            'requestId' => Fog::AWS::Mock.request_id,
            'CopyDBSnapshotResult' => {'DBSnapshot' => data.dup}
          }
          response
        end
      end
    end
  end
end
