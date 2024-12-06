module Fog
  module AWS
    class RDS
      class Real
        require 'fog/aws/parsers/rds/create_db_instance_read_replica'

        # create a read replica db instance
        # http://docs.amazonwebservices.com/AmazonRDS/latest/APIReference/API_CreateDBInstanceReadReplica.html
        # ==== Parameters
        # * DBInstanceIdentifier <~String> - name of the db instance to create
        # * SourceDBInstanceIdentifier <~String> - name of the db instance that will be the source. Must have backup retention on
        # * AutoMinorVersionUpgrade <~Boolean> Indicates that minor version upgrades will be applied automatically to the DB Instance during the maintenance window
        # * AvailabilityZone <~String> The availability zone to create the instance in
        # * DBInstanceClass <~String> The new compute and memory capacity of the DB Instance
        # * Port <~Integer> The port number on which the database accepts connections.
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        def create_db_instance_read_replica(instance_identifier, source_identifier, options={})
          request({
            'Action'  => 'CreateDBInstanceReadReplica',
            'DBInstanceIdentifier' => instance_identifier,
            'SourceDBInstanceIdentifier' => source_identifier,
            :parser   => Fog::Parsers::AWS::RDS::CreateDBInstanceReadReplica.new,
          }.merge(options))
        end
      end

      class Mock
        def create_db_instance_read_replica(instance_identifier, source_identifier, options={})
          # TODO: throw error when instance_identifier already exists,
          # or source_identifier doesn't exist

          source = self.data[:servers][source_identifier]
          data = {
            'AllocatedStorage'                      => source['AllocatedStorage'],
            'AutoMinorVersionUpgrade'               => options.key?('AutoMinorVersionUpgrade') ? options['AutoMinorVersionUpgrade'] : source['AutoMinorVersionUpgrade'],
            'AvailabilityZone'                      => options['AvailabilityZone'],
            'BackupRetentionPeriod'                 => options['BackupRetentionPeriod'] || 0,
            'CACertificateIdentifier'               => "rds-ca-2015",
            'DBInstanceClass'                       => options['DBInstanceClass'] || 'db.m1.small',
            'DBInstanceIdentifier'                  => instance_identifier,
            'DBInstanceStatus'                      => 'creating',
            'DBName'                                => source['DBName'],
            'DBParameterGroups'                     => source['DBParameterGroups'],
            'DBSecurityGroups'                      => source['DBSecurityGroups'],
            'Endpoint'                              => {},
            'Engine'                                => source['Engine'],
            'EngineVersion'                         => source['EngineVersion'],
            'InstanceCreateTime'                    => nil,
            'Iops'                                  => source['Iops'],
            'LatestRestorableTime'                  => nil,
            'LicenseModel'                          => 'general-public-license',
            'MasterUsername'                        => source['MasterUsername'],
            'MultiAZ'                               => false,
            'PendingModifiedValues'                 => {},
            'PreferredBackupWindow'                 => '08:00-08:30',
            'PreferredMaintenanceWindow'            => "mon:04:30-mon:05:00",
            'PubliclyAccessible'                    => !!options["PubliclyAccessible"],
            'ReadReplicaDBInstanceIdentifiers'      => [],
            'ReadReplicaSourceDBInstanceIdentifier' => source_identifier,
            'StorageType'                           => options['StorageType'] || 'standard',
            'StorageEncrypted'                      => false,
            'VpcSecurityGroups'                     => source['VpcSecurityGroups'],
          }
          self.data[:servers][instance_identifier] = data
          self.data[:servers][source_identifier]['ReadReplicaDBInstanceIdentifiers'] << instance_identifier

          response = Excon::Response.new
          response.body = {
            "ResponseMetadata"=>{ "RequestId"=> Fog::AWS::Mock.request_id },
            "CreateDBInstanceReadReplicaResult"=> {"DBInstance"=> data}
          }
          response.status = 200
          # This values aren't showed at creating time but at available time
          self.data[:servers][instance_identifier]["InstanceCreateTime"] = Time.now

          response
        end
      end
    end
  end
end
