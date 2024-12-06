module Fog
  module AWS
    class Elasticache
      class Cluster < Fog::Model
        # simple attributes
        identity :id, :aliases => 'CacheClusterId'
        attribute :auto_upgrade, :aliases => 'AutoMinorVersionUpgrade'
        attribute :status, :aliases => 'CacheClusterStatus'
        attribute :node_type, :aliases => 'CacheNodeType'
        attribute :engine, :aliases => 'Engine'
        attribute :engine_version, :aliases => 'EngineVersion'
        attribute :num_nodes, :aliases => 'NumCacheNodes'
        attribute :zone, :aliases => 'PreferredAvailabilityZone'
        attribute :port, :aliases => 'Port'
        attribute :maintenance_window, :aliases => 'PreferredMaintenanceWindow'
        # complex attributes
        attribute :nodes, :aliases => 'CacheNodes', :type => :array
        attribute :parameter_group, :aliases => 'CacheParameterGroup'
        attribute :pending_values, :aliases => 'PendingModifiedValues'
        attribute :create_time, :aliases => 'CacheClusterCreateTime', :type => :timestamp
        attribute :cache_security_groups, :aliases => 'CacheSecurityGroups', :type => :array
        attribute :security_groups, :aliases => 'SecurityGroups', :type => :array
        attribute :notification_config, :aliases => 'NotificationConfiguration'
        attribute :cache_subnet_group_name, :aliases => 'CacheSubnetGroupName'
        attribute :vpc_security_groups, :aliases => 'VpcSecurityGroups', :type => :array
        attribute :s3_snapshot_location, :aliases => 'SnapshotArns', :type => :array
        attribute :configuration_endpoint, :aliases => 'ConfigurationEndpoint'

        attr_accessor :parameter_group_name

        def ready?
          status == 'available'
        end

        def destroy
          requires :id
          service.delete_cache_cluster(id)
          true
        end

        def save
          requires :id

          parameter_group     ||= Hash.new
          notification_config ||= Hash.new

          service.create_cache_cluster(
            id, {
              :node_type                    => node_type,
              :security_group_names         => security_groups,
              :num_nodes                    => num_nodes,
              :auto_minor_version_upgrade   => auto_upgrade,
              :engine                       => engine,
              :engine_version               => engine_version,
              :notification_topic_arn       => notification_config['TopicArn'],
              :port                         => port,
              :preferred_availablility_zone => zone,
              :preferred_maintenance_window => maintenance_window,
              :s3_snapshot_location         => s3_snapshot_location,
              :parameter_group_name         => parameter_group_name || parameter_group['CacheParameterGroupName'],
              :cache_subnet_group_name      => cache_subnet_group_name,
              :vpc_security_groups          => vpc_security_groups,
            }
          )
        end
      end
    end
  end
end
