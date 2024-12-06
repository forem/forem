module Fog
  module AWS
    class RDS
      class SubnetGroup < Fog::Model
        identity   :id, :aliases => ['DBSubnetGroupName', :name]
        attribute  :description, :aliases => 'DBSubnetGroupDescription'
        attribute  :status, :aliases => 'SubnetGroupStatus'
        attribute  :vpc_id, :aliases => 'VpcId'
        attribute  :subnet_ids, :aliases => 'Subnets'

        def ready?
          requires :status
          status == 'Complete'
        end

        def save
          requires :description, :id, :subnet_ids
          service.create_db_subnet_group(id, subnet_ids, description)
          reload
        end

        def destroy
          requires :id
          service.delete_db_subnet_group(id)
        end
      end
    end
  end
end
