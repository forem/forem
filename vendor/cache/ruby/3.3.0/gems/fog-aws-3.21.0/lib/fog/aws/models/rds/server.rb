module Fog
  module AWS
    class RDS
      class Server < Fog::Model
        identity  :id, :aliases => 'DBInstanceIdentifier'

        attribute :allocated_storage,                  :aliases => 'AllocatedStorage', :type => :integer
        attribute :auto_minor_version_upgrade,         :aliases => 'AutoMinorVersionUpgrade'
        attribute :availability_zone,                  :aliases => 'AvailabilityZone'
        attribute :backup_retention_period,            :aliases => 'BackupRetentionPeriod', :type => :integer
        attribute :ca_certificate_id,                  :aliases => 'CACertificateIdentifier'
        attribute :character_set_name,                 :aliases => 'CharacterSetName'
        attribute :cluster_id,                         :aliases => 'DBClusterIdentifier'
        attribute :created_at,                         :aliases => 'InstanceCreateTime', :type => :time
        attribute :db_name,                            :aliases => 'DBName'
        attribute :db_parameter_groups,                :aliases => 'DBParameterGroups'
        attribute :db_security_groups,                 :aliases => 'DBSecurityGroups', :type => :array
        attribute :db_subnet_group_name,               :aliases => 'DBSubnetGroupName'
        attribute :dbi_resource_id,                    :aliases => 'DbiResourceId'
        attribute :enable_iam_database_authentication, :aliases => 'EnableIAMDatabaseAuthentication', :type => :boolean
        attribute :endpoint,                           :aliases => 'Endpoint'
        attribute :engine,                             :aliases => 'Engine'
        attribute :engine_version,                     :aliases => 'EngineVersion'
        attribute :flavor_id,                          :aliases => 'DBInstanceClass'
        attribute :iops,                               :aliases => 'Iops', :type => :integer
        attribute :kms_key_id,                         :aliases => 'KmsKeyId'
        attribute :last_restorable_time,               :aliases => 'LatestRestorableTime', :type => :time
        attribute :license_model,                      :aliases => 'LicenseModel'
        attribute :master_username,                    :aliases => 'MasterUsername'
        attribute :multi_az,                           :aliases => 'MultiAZ', :type => :boolean
        attribute :pending_modified_values,            :aliases => 'PendingModifiedValues'
        attribute :preferred_backup_window,            :aliases => 'PreferredBackupWindow'
        attribute :preferred_maintenance_window,       :aliases => 'PreferredMaintenanceWindow'
        attribute :publicly_accessible,                :aliases => 'PubliclyAccessible'
        attribute :read_replica_identifiers,           :aliases => 'ReadReplicaDBInstanceIdentifiers', :type => :array
        attribute :read_replica_source,                :aliases => 'ReadReplicaSourceDBInstanceIdentifier'
        attribute :state,                              :aliases => 'DBInstanceStatus'
        attribute :storage_encrypted,                  :aliases => 'StorageEncrypted', :type => :boolean
        attribute :storage_type,                       :aliases => 'StorageType'
        attribute :tde_credential_arn,                 :aliases => 'TdeCredentialArn'
        attribute :vpc_security_groups,                :aliases => 'VpcSecurityGroups', :type => :array
        attribute :db_subnet_group,                    :aliases => 'DBSubnetGroup'

        attr_accessor :password, :parameter_group_name, :security_group_names, :port, :source_snapshot_id

        def cluster
          return nil unless cluster_id
          service.clusters.get(cluster_id)
        end

        def create_read_replica(replica_id, options={})
          options[:security_group_names] ||= options['DBSecurityGroups']
          params = self.class.new(options).attributes_to_params
          service.create_db_instance_read_replica(replica_id, id, params)
          service.servers.get(replica_id)
        end

        def ready?
          state == 'available'
        end

        def destroy(snapshot_identifier=nil)
          requires :id
          service.delete_db_instance(id, snapshot_identifier, snapshot_identifier.nil?)
          true
        end

        def reboot
          service.reboot_db_instance(id)
          true
        end

        def snapshots
          requires :id
          service.snapshots(:server => self)
        end

        def tags
          requires :id
          service.list_tags_for_resource(id).
            body['ListTagsForResourceResult']['TagList']
        end

        def add_tags(new_tags)
          requires :id
          service.add_tags_to_resource(id, new_tags)
          tags
        end

        def remove_tags(tag_keys)
          requires :id
          service.remove_tags_from_resource(id, tag_keys)
          tags
        end

        def promote_read_replica
          requires :id

          data = service.promote_read_replica(id).body["PromoteReadReplicaResult"]["DBInstance"]

          merge_attributes(data)
        end

        alias promote promote_read_replica

        def modify(immediately, options)
          options[:security_group_names] ||= options['DBSecurityGroups']
          params = self.class.new(options).attributes_to_params
          data = service.modify_db_instance(id, immediately, params)
          merge_attributes(data.body['ModifyDBInstanceResult']['DBInstance'])
          true
        end

        def save
          if source_snapshot_id
            requires :id
            data = service.restore_db_instance_from_db_snapshot(source_snapshot_id, id, attributes_to_params)
            merge_attributes(data.body['RestoreDBInstanceFromDBSnapshotResult']['DBInstance'])
          else
            requires :engine

            if engine.start_with?('aurora')
              requires :cluster_id
              self.flavor_id ||= 'db.r4.large'
            else
              requires :master_username
              requires :password
              requires :allocated_storage
              self.flavor_id ||= 'db.m4.large'
            end

            data = service.create_db_instance(id, attributes_to_params)
            merge_attributes(data.body['CreateDBInstanceResult']['DBInstance'])
            true
          end
        end

        # Converts attributes to a parameter hash suitable for requests
        def attributes_to_params
          options = {
            'AllocatedStorage'                => allocated_storage,
            'AutoMinorVersionUpgrade'         => auto_minor_version_upgrade,
            'AvailabilityZone'                => availability_zone,
            'BackupRetentionPeriod'           => backup_retention_period,
            'DBClusterIdentifier'             => cluster_id,
            'DBInstanceClass'                 => flavor_id,
            'DBInstanceIdentifier'            => id,
            'DBName'                          => db_name,
            'DBParameterGroupName'            => parameter_group_name || attributes['DBParameterGroupName'],
            'DBSecurityGroups'                => security_group_names,
            'DBSubnetGroupName'               => db_subnet_group_name,
            'EnableIAMDatabaseAuthentication' => enable_iam_database_authentication,
            'Engine'                          => engine,
            'EngineVersion'                   => engine_version,
            'Iops'                            => iops,
            'KmsKeyId'                        => kms_key_id,
            'LicenseModel'                    => license_model,
            'MasterUserPassword'              => password || attributes['MasterUserPassword'],
            'MasterUsername'                  => master_username,
            'MultiAZ'                         => multi_az,
            'Port'                            => port || attributes['Port'],
            'PreferredBackupWindow'           => preferred_backup_window,
            'PreferredMaintenanceWindow'      => preferred_maintenance_window,
            'PubliclyAccessible'              => publicly_accessible,
            'StorageEncrypted'                => storage_encrypted,
            'StorageType'                     => storage_type,
            'VpcSecurityGroups'               => vpc_security_groups,
          }

          options.delete_if {|key, value| value.nil?}
        end
      end
    end
  end
end
