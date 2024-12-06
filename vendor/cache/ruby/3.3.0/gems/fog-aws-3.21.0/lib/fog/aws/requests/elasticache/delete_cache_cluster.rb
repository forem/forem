module Fog
  module AWS
    class Elasticache
      class Real
        require 'fog/aws/parsers/elasticache/describe_cache_clusters'

        # Deletes a Cache Cluster
        #
        # === Parameter (required):
        # *  id <~String> - The ID of the cache cluster to delete
        # === Returns
        # * response <~Excon::Response>:
        #   * body <~Hash>
        def delete_cache_cluster(cluster_id)
          request(
            'Action'          => 'DeleteCacheCluster',
            'CacheClusterId'  => cluster_id,
            :parser => Fog::Parsers::AWS::Elasticache::DescribeCacheClusters.new
          )
        end
      end

      class Mock
        def delete_cache_cluster(cluster_id)
          response        = Excon::Response.new
          cluster         = self.data[:clusters][cluster_id]
          cluster['CacheClusterStatus'] = 'deleting'
          response.body = {
            'CacheClusters'     => self.data[:clusters].values,
            'ResponseMetadata'  => { 'RequestId' => Fog::AWS::Mock.request_id }
          }
          self.data[:clusters].delete(cluster_id)
          response
        end
      end
    end
  end
end
