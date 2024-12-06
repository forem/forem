require 'fog/aws/models/elasticache/subnet_group'

module Fog
  module AWS
    class Elasticache
      class SubnetGroups < Fog::Collection
        model Fog::AWS::Elasticache::SubnetGroup

        def all
          data = service.describe_cache_subnet_groups.body['DescribeCacheSubnetGroupsResult']['CacheSubnetGroups']
          load(data) # data is an array of attribute hashes
        end

        def get(identity)
          data = service.describe_cache_subnet_groups(identity).body['DescribeCacheSubnetGroupsResult']['CacheSubnetGroups'].first
          new(data) # data is an attribute hash
        rescue Fog::AWS::Elasticache::NotFound
          nil
        end
      end
    end
  end
end
