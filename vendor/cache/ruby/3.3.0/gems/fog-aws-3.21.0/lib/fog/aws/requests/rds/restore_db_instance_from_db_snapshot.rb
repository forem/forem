module Fog
  module AWS
    class RDS
      class Real
        require 'fog/aws/parsers/rds/restore_db_instance_from_db_snapshot'

        # Restores a DB Instance from a DB Snapshot
        # http://docs.amazonwebservices.com/AmazonRDS/latest/APIReference/index.html?API_RestoreDBInstanceFromDBSnapshot.html
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        def restore_db_instance_from_db_snapshot(snapshot_id, db_name, opts={})
          request({
            'Action'  => 'RestoreDBInstanceFromDBSnapshot',
            'DBSnapshotIdentifier' => snapshot_id,
            'DBInstanceIdentifier' => db_name,
            :parser   => Fog::Parsers::AWS::RDS::RestoreDBInstanceFromDBSnapshot.new,
          }.merge(opts))
        end
      end

      class Mock
        def restore_db_instance_from_db_snapshot(snapshot_id, db_name, options={})

          if self.data[:servers] and self.data[:servers][db_name]
            raise Fog::AWS::RDS::IdentifierTaken.new("DBInstanceAlreadyExists #{response.body.to_s}")
          end

          unless self.data[:snapshots] and snapshot = self.data[:snapshots][snapshot_id]
            raise Fog::AWS::RDS::NotFound.new("DBSnapshotNotFound #{response.body.to_s}")
          end

          if !!options["MultiAZ"] && !!options["AvailabilityZone"]
            raise Fog::AWS::RDS::InvalidParameterCombination.new('Requesting a specific availability zone is not valid for Multi-AZ instances.')
          end

          option_group_membership =
            if option_group_name = options['OptionGroupName']
              [{ 'OptionGroupMembership' =>
                [{ 'OptionGroupName' => option_group_name, 'Status' => "pending-apply"}] }]
            else
              [{ 'OptionGroupMembership' =>
                [{ 'OptionGroupName' => 'default: mysql-5.6', 'Status' => "pending-apply"}] }]
            end

          data = {
            "AllocatedStorage"                 => snapshot['AllocatedStorage'],
            "AutoMinorVersionUpgrade"          => options['AutoMinorVersionUpgrade'].nil? ? true : options['AutoMinorVersionUpgrade'],
            "AvailabilityZone"                 => options['AvailabilityZone'],
            "BackupRetentionPeriod"            => options['BackupRetentionPeriod'] || 1,
            "CACertificateIdentifier"          => 'rds-ca-2015',
            "DBInstanceClass"                  => options['DBInstanceClass'] || 'db.m3.medium',
            "DBInstanceIdentifier"             => db_name,
            "DBInstanceStatus"                 => 'creating',
            "DBName"                           => options['DBName'],
            "DBParameterGroups"                => [{'DBParameterGroupName'=>'default.mysql5.5', 'ParameterApplyStatus'=>'in-sync'}],
            "DBSecurityGroups"                 => [{'Status'=>'active', 'DBSecurityGroupName'=>'default'}],
            "Endpoint"                         => {},
            "Engine"                           => options['Engine'] || snapshot['Engine'],
            "EngineVersion"                    => options['EngineVersion'] || snapshot['EngineVersion'],
            "InstanceCreateTime"               => nil,
            "Iops"                             => options['Iops'],
            "LicenseModel"                     => options['LicenseModel'] || snapshot['LicenseModel'] || 'general-public-license',
            "MasterUsername"                   => options['MasterUsername'] || snapshot['MasterUsername'],
            "MultiAZ"                          => !!options['MultiAZ'],
            "OptiongroupMemberships"           => option_group_membership,
            "PendingModifiedValues"            => { 'MasterUserPassword' => '****' }, # This clears when is available
            "PreferredBackupWindow"            => '08:00-08:30',
            "PreferredMaintenanceWindow"       => 'mon:04:30-mon:05:00',
            "PubliclyAccessible"               => true,
            "ReadReplicaDBInstanceIdentifiers" => [],
            "StorageType"                      => options['StorageType'] || (options['Iops'] ? 'io1' : 'standard'),
            "VpcSecurityGroups"                => nil,
            "StorageEncrypted"                 => false,
          }

          self.data[:servers][db_name] = data
          response = Excon::Response.new
          response.body =
            { "ResponseMetadata" => { "RequestId" => Fog::AWS::Mock.request_id },
              "RestoreDBInstanceFromDBSnapshotResult" => { "DBInstance" => data }
          }
          response.status = 200
          self.data[:servers][db_name]["InstanceCreateTime"] = Time.now
          response
        end
      end
    end
  end
end
