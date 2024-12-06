module Fog
  module AWS
    class Elasticache
      class Real
        require 'fog/aws/parsers/elasticache/single_cache_cluster'

        # Reboots some or all of an existing cache cluster's nodes
        # Returns a cache cluster description
        #
        # === Required Parameters
        # * id <~String> - The ID of the existing cluster to be rebooted
        # === Optional Parameters
        # * nodes_to_reboot <~Array> - Array of node IDs to reboot
        # === Returns
        # * response <~Excon::Response>:
        #   * body <~Hash>
        def reboot_cache_cluster(id, nodes_to_reboot)
          # Construct CacheNodeIdsToReboot parameters in the format:
          #   CacheNodeIdsToReboot.member.N => "node_id"
          node_ids = nodes_to_reboot || []
          node_id_params = node_ids.reduce({}) do |node_hash, node_id|
            index = node_ids.index(node_id) + 1
            node_hash["CacheNodeIdsToReboot.member.#{index}"] = node_id
            node_hash
          end
          # Merge the CacheNodeIdsToReboot parameters with the normal options
          request(node_id_params.merge(
            'Action'          => 'RebootCacheCluster',
            'CacheClusterId'  => id,
            :parser => Fog::Parsers::AWS::Elasticache::SingleCacheCluster.new
          ))
        end
      end

      class Mock
        def reboot_cache_cluster(id, nodes_to_reboot)
          response        = Excon::Response.new
          response.body   = {
            'CacheCluster' => self.data[:clusters][id].merge({
              'CacheClusterStatus' => 'rebooting cache cluster nodes'
            }),
            'ResponseMetadata'  => { 'RequestId' => Fog::AWS::Mock.request_id }
          }
          response
        end
      end
    end
  end
end
