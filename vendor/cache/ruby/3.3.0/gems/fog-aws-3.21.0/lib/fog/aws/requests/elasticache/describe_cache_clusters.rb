module Fog
  module AWS
    class Elasticache
      class Real
        require 'fog/aws/parsers/elasticache/describe_cache_clusters'

        # Returns a list of Cache Cluster descriptions
        #
        # === Parameters (optional)
        # * id - The ID of an existing cache cluster
        # * options <~Hash> (optional):
        # *  :marker <~String> - marker provided in the previous request
        # *  :max_records <~Integer> - the maximum number of records to include
        # *  :show_node_info <~Boolean> - whether to show node info
        # === Returns
        # * response <~Excon::Response>:
        #   * body <~Hash>
        def describe_cache_clusters(id = nil, options = {})
          request({
            'Action'            => 'DescribeCacheClusters',
            'CacheClusterId'    => id,
            'Marker'            => options[:marker],
            'MaxRecords'        => options[:max_records],
            'ShowCacheNodeInfo' => options[:show_node_info],
            :parser => Fog::Parsers::AWS::Elasticache::DescribeCacheClusters.new
          })
        end
      end

      class Mock
        def describe_cache_clusters(id = nil, options = {})
          response        = Excon::Response.new
          all_clusters    = self.data[:clusters].values.map do |cluster|
            cluster.merge!(options[:show_node_info] ? {
              'CacheClusterCreateTime'    => DateTime.now - 60,
              'PreferredAvailabilityZone' => 'us-east-1a'
            } : {})
          end
          if (id != nil) && (all_clusters.empty?)
            raise Fog::AWS::Elasticache::NotFound
          end
          response.body = {
            'CacheClusters'     => all_clusters,
            'ResponseMetadata'  => { 'RequestId' => Fog::AWS::Mock.request_id }
          }
          response
        end
      end
    end
  end
end
