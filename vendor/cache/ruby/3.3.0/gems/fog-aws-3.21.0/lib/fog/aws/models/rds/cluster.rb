module Fog
  module AWS
    class RDS
      class Cluster < Fog::Model
        identity :id, :aliases => 'DBClusterIdentifier'

        attribute :allocated_storage,            :aliases => 'AllocatedStorage',          :type => :integer
        attribute :backup_retention_period,      :aliases => 'BackupRetentionPeriod',     :type => :integer
        attribute :db_cluster_members,           :aliases => 'DBClusterMembers',          :type => :array
        attribute :db_cluster_parameter_group,   :aliases => 'DBClusterParameterGroup'
        attribute :db_subnet_group,              :aliases => 'DBSubnetGroupName'
        attribute :endpoint,                     :aliases => 'Endpoint'
        attribute :engine,                       :aliases => 'Engine'
        attribute :engine_version,               :aliases => 'EngineVersion'
        attribute :password,                     :aliases => 'MasterUserPassword'
        attribute :master_username,              :aliases => 'MasterUsername'
        attribute :port,                         :aliases => 'Port',                      :type => :integer
        attribute :preferred_backup_window,      :aliases => 'PreferredBackupWindow'
        attribute :preferred_maintenance_window, :aliases => 'PreferredMaintenanceWindow'
        attribute :state,                        :aliases => 'Status'
        attribute :vpc_security_groups,          :aliases => 'VpcSecurityGroups'

        attr_accessor :storage_encrypted #not in the response

        def ready?
          # [2019.01] I don't think this is going to work, at least not with Aurora
          # clusters. In my testing, the state reported by Fog for an Aurora cluster
          # is "active" as soon as the cluster is retrievable from AWS, and the
          # value doesn't change after that. Contrast that with the AWS Console UI,
          # which reports the cluster as "Creating" while it's being created. I don't
          # know where Fog is getting the state value from, but I don't think it's
          # correct, at least not for the purpose of knowing if the Cluster is ready
          # to have individual instances added to it.
          state == 'available' || state == 'active'
        end

        def snapshots
          requires :id
          service.cluster_snapshots(:cluster => self)
        end

        def servers(set=db_cluster_members)
          set.map do |member|
            service.servers.get(member['DBInstanceIdentifier'])
          end
        end

        def master
          db_cluster_members.detect { |member| member["master"] }
        end

        def replicas
          servers(db_cluster_members.select { |member| !member["master"] })
        end

        def has_replica?(replica_name)
          replicas.detect { |replica| replica.id == replica_name }
        end

        def destroy(snapshot_identifier=nil)
          requires :id
          service.delete_db_cluster(id, snapshot_identifier, snapshot_identifier.nil?)
          true
        end

        def save
          requires :id
          requires :engine
          requires :master_username
          requires :password

          data = service.create_db_cluster(id, attributes_to_params)
          merge_attributes(data.body['CreateDBClusterResult']['DBCluster'])
          true
        end

        def attributes_to_params
          options = {
            'AllocatedStorage'           => allocated_storage,
            'BackupRetentionPeriod'      => backup_retention_period,
            'DBClusterIdentifier'        => identity,
            'DBClusterParameterGroup'    => db_cluster_parameter_group,
            'DBSubnetGroupName'          => db_subnet_group,
            'Endpoint'                   => endpoint,
            'Engine'                     => engine,
            'EngineVersion'              => engine_version,
            'MasterUserPassword'         => password,
            'MasterUsername'             => master_username,
            'PreferredBackupWindow'      => preferred_backup_window,
            'PreferredMaintenanceWindow' => preferred_maintenance_window,
            'Status'                     => state,
            'StorageEncrypted'           => storage_encrypted,
            'VpcSecurityGroups'          => vpc_security_groups,
          }

          options.delete_if { |key,value| value.nil? }
        end
      end
    end
  end
end
