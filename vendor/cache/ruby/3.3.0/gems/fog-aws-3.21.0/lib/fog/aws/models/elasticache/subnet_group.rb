module Fog
  module AWS
    class Elasticache
      class SubnetGroup < Fog::Model
        identity   :id, :aliases => ['CacheSubnetGroupName', :name]
        attribute  :description, :aliases => 'CacheSubnetGroupDescription'
        attribute  :vpc_id, :aliases => 'VpcId'
        attribute  :subnet_ids, :aliases => 'Subnets'

        def ready?
          # Just returning true, as Elasticache subnet groups
          # seem to not have a status, unlike RDS subnet groups.
          true
        end

        def save
          requires :description, :id, :subnet_ids
          service.create_cache_subnet_group(id, subnet_ids, description)
          reload
        end

        def destroy
          requires :id
          service.delete_cache_subnet_group(id)
          true
        end
      end
    end
  end
end
