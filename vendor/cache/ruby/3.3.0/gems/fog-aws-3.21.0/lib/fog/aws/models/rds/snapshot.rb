module Fog
  module AWS
    class RDS
      class Snapshot < Fog::Model
        identity  :id, :aliases => ['DBSnapshotIdentifier', 'DBClusterSnapshotIdentifier', :name]

        attribute :allocated_storage,   :aliases => 'AllocatedStorage',    :type => :integer
        attribute :availability_zone,   :aliases => 'AvailabilityZone'
        attribute :cluster_created_at,  :aliases => 'ClusterCreateTime',   :type => :time
        attribute :cluster_id,          :aliases => 'DBClusterIdentifier'
        attribute :created_at,          :aliases => 'SnapshotCreateTime',  :type => :time
        attribute :engine,              :aliases => 'Engine'
        attribute :engine_version,      :aliases => 'EngineVersion'
        attribute :instance_created_at, :aliases => 'InstanceCreateTime',  :type => :time
        attribute :instance_id,         :aliases => 'DBInstanceIdentifier'
        attribute :iops,                :aliases => 'Iops',                :type => :integer
        attribute :license_model,       :aliases => 'LicenseModel'
        attribute :master_username,     :aliases => 'MasterUsername'
        attribute :port,                :aliases => 'Port',                :type => :integer
        attribute :publicly_accessible, :aliases => 'PubliclyAccessible'
        attribute :state,               :aliases => 'Status'
        attribute :storage_type,        :aliases => 'StorageType'
        attribute :type,                :aliases => 'SnapshotType'

        def ready?
          state == 'available'
        end

        def destroy
          requires :id
          requires_one :instance_id, :cluster_id

          if instance_id
            service.delete_db_snapshot(id)
          else
            service.delete_db_cluster_snapshot(id)
          end
          true
        end

        def save
          requires_one :instance_id, :cluster_id
          requires :id

          data = if instance_id
                   service.create_db_snapshot(instance_id, id).body['CreateDBSnapshotResult']['DBSnapshot']
                 elsif cluster_id
                   service.create_db_cluster_snapshot(cluster_id, id).body['CreateDBClusterSnapshotResult']['DBClusterSnapshot']
                 end
          merge_attributes(data)
          true
        end

        def server
          requires :instance_id
          service.servers.get(instance_id)
        end

        def cluster
          requires :cluster_id
          service.clusters.get(cluster_id)
        end
      end
    end
  end
end
