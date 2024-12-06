module Fog
  module AWS
    class Elasticache
      class Real
        require 'fog/aws/parsers/elasticache/single_cache_cluster'
        # creates a cache cluster
        #
        # === Required Parameters
        # * id <~String> - A unique cluster ID - 20 characters max.
        # === Optional Parameters
        # * options <~Hash> - All optional parameters should be set in this Hash:
        #   * :node_type <~String> - The size (flavor) of the cache Nodes
        #   * :security_group_names <~Array> - Array of Elasticache::SecurityGroup names
        #   * :vpc_security_groups <~Array> - Array
        #   * :num_nodes <~Integer> - The number of nodes in the Cluster
        #   * :auto_minor_version_upgrade <~TrueFalseClass>
        #   * :parameter_group_name <~String> - Name of the Cluster's ParameterGroup
        #   * :engine <~String> - The Cluster's caching software (memcached)
        #   * :engine_version <~String> - The Cluster's caching software version
        #   * :notification_topic_arn <~String> - Amazon SNS Resource Name
        #   * :port <~Integer> - The memcached port number
        #   * :preferred_availablility_zone <~String>
        #   * :preferred_maintenance_window <~String>
        #   * :cache_subnet_group_name <~String>
        #   * :s3_snapshot_location <~String> - Amazon resource location for snapshot
        # === Returns
        # * response <~Excon::Response>:
        #   * body <~Hash>
        def create_cache_cluster(id, options = {})
          req_options = {
            'Action'          => 'CreateCacheCluster',
            'CacheClusterId'  => id.strip,
            'CacheNodeType'   => options[:node_type]  || 'cache.m1.large',
            'Engine'          => options[:engine]     || 'memcached',
            'NumCacheNodes'   => options[:num_nodes]  || 1,
            'AutoMinorVersionUpgrade'     => options[:auto_minor_version_upgrade],
            'CacheParameterGroupName'     => options[:parameter_group_name],
            'CacheSubnetGroupName'        => options[:cache_subnet_group_name],
            'EngineVersion'               => options[:engine_version],
            'NotificationTopicArn'        => options[:notification_topic_arn],
            'Port'                        => options[:port],
            'PreferredAvailabilityZone'   => options[:preferred_availablility_zone],
            'PreferredMaintenanceWindow'  => options[:preferred_maintenance_window],
            :parser => Fog::Parsers::AWS::Elasticache::SingleCacheCluster.new
          }

          if s3_snapshot_location = options.delete(:s3_snapshot_location)
            req_options.merge!(Fog::AWS.indexed_param('SnapshotArns.member.%d', [*s3_snapshot_location]))
          end

          if cache_security_groups = options.delete(:security_group_names)
              req_options.merge!(Fog::AWS.indexed_param('CacheSecurityGroupNames.member.%d', [*cache_security_groups]))
          end

          if vpc_security_groups = options.delete(:vpc_security_groups)
              req_options.merge!(Fog::AWS.indexed_param('SecurityGroupIds.member.%d', [*vpc_security_groups]))
          end

          request( req_options )
        end
      end

      class Mock
        def create_cache_cluster(id, options = {})
          response        = Excon::Response.new
          cluster         = { # create an in-memory representation of this cluster
            'CacheClusterId'  => id.strip,
            'NumCacheNodes'   => options[:num_nodes]      || 1,
            'CacheNodeType'   => options[:node_type]      || 'cache.m1.large',
            'Engine'          => options[:engine]         || 'memcached',
            'EngineVersion'   => options[:engine_version] || '1.4.5',
            'CacheClusterStatus'  => 'available',
            'CacheNodes'          => create_cache_nodes(id.strip, options[:num_nodes]),
            'CacheSecurityGroups' => [],
            'SecurityGroups'  => [],
            'CacheParameterGroup' => { 'CacheParameterGroupName' =>
                options[:parameter_group_name] || 'default.memcached1.4' },
            'CacheSubnetGroupName' => options[:cache_subnet_group_name],
            'PendingModifiedValues'       => {},
            'AutoMinorVersionUpgrade'     =>
              options[:auto_minor_version_upgrade]    || 'true',
            'PreferredMaintenanceWindow'  =>
              options[:preferred_maintenance_window]  || 'sun:05:00-sun:09:00',
          }
          self.data[:clusters][id] = cluster  # store the in-memory cluster
          response.body = {
            'CacheCluster' => cluster.merge({'CacheClusterStatus' => 'creating'}),
            'ResponseMetadata' => { 'RequestId' => Fog::AWS::Mock.request_id }
          }
          response
        end
      end
    end
  end
end
