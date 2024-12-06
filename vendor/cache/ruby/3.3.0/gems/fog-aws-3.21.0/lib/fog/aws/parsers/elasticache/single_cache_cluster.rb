module Fog
  module Parsers
    module AWS
      module Elasticache
        require 'fog/aws/parsers/elasticache/cache_cluster_parser'

        class SingleCacheCluster < CacheClusterParser
          def end_element(name)
            case name
            when 'CacheCluster'
              @response[name] = @cache_cluster
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
