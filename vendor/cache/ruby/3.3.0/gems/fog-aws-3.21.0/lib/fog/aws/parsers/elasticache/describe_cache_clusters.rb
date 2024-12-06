module Fog
  module Parsers
    module AWS
      module Elasticache
        require 'fog/aws/parsers/elasticache/cache_cluster_parser'

        class DescribeCacheClusters < CacheClusterParser
          def reset
            super
            @response['CacheClusters'] = []
          end

          def end_element(name)
            case name
            when 'CacheCluster'
              @response["#{name}s"] << @cache_cluster
              reset_cache_cluster
            else
              super
            end
          end
        end
      end
    end
  end
end
