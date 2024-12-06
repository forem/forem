module Fog
  module AWS
    class RDS
      class InstanceOption < Fog::Model
        attribute :multi_az_capable, :aliases => 'MultiAZCapable', :type => :boolean
        attribute :engine, :aliases => 'Engine'
        attribute :license_model, :aliases => 'LicenseModel'
        attribute :read_replica_capable, :aliases => 'ReadReplicaCapable', :type => :boolean
        attribute :engine_version, :aliases => 'EngineVersion'
        attribute :availability_zones, :aliases => 'AvailabilityZones', :type => :array
        attribute :db_instance_class, :aliases => 'DBInstanceClass'
        attribute :vpc, :aliases => 'Vpc', :type => :boolean
        attribute :supports_iops, :aliases => 'SupportsIops', :type => :boolean
        attribute :supports_enhanced_monitoring, :aliases => 'SupportsEnhancedMonitoring', :type => :boolean
        attribute :supports_iam_database_authentication, :aliases => 'SupportsIAMDatabaseAuthentication', :type => :boolean
        attribute :supports_performance_insights, :aliases => 'SupportsPerformanceInsights', :type => :boolean
        attribute :supports_storage_encryption, :aliases => 'SupportsStorageEncryption', :type => :boolean
        attribute :storage_type, :aliases => 'StorageType'
      end
    end
  end
end
