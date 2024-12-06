module Fog
  module AWS
    class Elasticache
      class Real
        require 'fog/aws/parsers/elasticache/single_cache_cluster'

        # Modifies an existing cache cluster
        # Returns a cache cluster description
        #
        # === Required Parameters
        # * id <~String> - The ID of the existing cluster to be modified
        # === Optional Parameters
        # * options <~Hash> - All optional parameters should be set in this Hash:
        #   * :apply_immediately <~TrueFalseClass> - whether to apply changes now
        #   * :auto_minor_version_upgrade <~TrueFalseClass>
        #   * :num_nodes <~Integer> - The number of nodes in the Cluster
        #   * :nodes_to_remove <~Array> - Array of node IDs to delete
        #   * :security_group_names <~Array> - Array of Elasticache::SecurityGroup names
        #   * :parameter_group_name <~String> - Name of the Cluster's ParameterGroup
        #   * :engine_version <~String> - The Cluster's caching software version
        #   * :notification_topic_arn <~String> - Amazon SNS Resource Name
        #   * :notification_topic_status <~String> - Amazon SNS Topic status
        #   * :preferred_maintenance_window <~String>
        # === Returns
        # * response <~Excon::Response>:
        #   * body <~Hash>
        def modify_cache_cluster(id, options = {})
          # Construct Cache Security Group parameters in the format:
          #   CacheSecurityGroupNames.member.N => "security_group_name"
          group_names = options[:security_group_names] || []
          sec_group_params = group_names.reduce({}) do |group_hash, name|
            index = group_names.index(name) + 1
            group_hash["CacheSecurityGroupNames.member.#{index}"] = name
            group_hash
          end
          # Construct CacheNodeIdsToRemove parameters in the format:
          #   CacheNodeIdsToRemove.member.N => "node_id"
          node_ids = options[:nodes_to_remove] || []
          node_id_params = node_ids.reduce({}) do |node_hash, node_id|
            index = node_ids.index(node_id) + 1
            node_hash["CacheNodeIdsToRemove.member.#{index}"] = node_id
            node_hash
          end
          # Merge the Cache Security Group parameters with the normal options
          request(node_id_params.merge(sec_group_params.merge(
            'Action'                      => 'ModifyCacheCluster',
            'CacheClusterId'              => id.strip,
            'ApplyImmediately'            => options[:apply_immediately],
            'NumCacheNodes'               => options[:num_nodes],
            'AutoMinorVersionUpgrade'     => options[:auto_minor_version_upgrade],
            'CacheParameterGroupName'     => options[:parameter_group_name],
            'EngineVersion'               => options[:engine_version],
            'NotificationTopicArn'        => options[:notification_topic_arn],
            'NotificationTopicStatus'     => options[:notification_topic_status],
            'PreferredMaintenanceWindow'  => options[:preferred_maintenance_window],
            :parser => Fog::Parsers::AWS::Elasticache::SingleCacheCluster.new
          )))
        end
      end

      class Mock
        def modify_cache_cluster(id, options = {})
          response        = Excon::Response.new
          cluster         = self.data[:clusters][id]
          pending_values  = Hash.new
          # For any given option, update the cluster's corresponding value
          { :auto_minor_version_upgrade   => 'AutoMinorVersionUpgrade',
            :preferred_maintenance_window => 'PreferredMaintenanceWindow',
            :engine_version               => 'EngineVersion',
            :num_nodes                    => 'NumCacheNodes',
          }.each do |option, cluster_key|
            if options[option] != nil
              cluster[cluster_key] = options[option].to_s
              pending_values[cluster_key] = options[option]
            end
          end
          cache['CacheParameterGroup'] = {
            'CacheParameterGroupName' => options[:parameter_group_name]
          } if options[:parameter_group_name]
          if options[:num_nodes] || options[:engine_version]
            cluster['CacheNodes'] =
              create_cache_nodes(cluster['CacheClusterId'], options[:num_nodes])
            cluster['NumCacheNodes'] = cluster['CacheNodes'].size
          end
          if options[:nodes_to_remove]
            pending_values['CacheNodeId'] = options[:nodes_to_remove].join(',')
          end
          response.body = {
            'CacheCluster' => cluster.merge({
              'PendingModifiedValues' => pending_values
            }),
            'ResponseMetadata' => { 'RequestId' => Fog::AWS::Mock.request_id }
          }
          response
        end
      end
    end
  end
end
