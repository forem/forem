require 'fog/aws/models/rds/subnet_group'

module Fog
  module AWS
    class RDS
      class SubnetGroups < Fog::Collection
        model Fog::AWS::RDS::SubnetGroup

        def all
          data = service.describe_db_subnet_groups.body['DescribeDBSubnetGroupsResult']['DBSubnetGroups']
          load(data) # data is an array of attribute hashes
        end

        def get(identity)
          data = service.describe_db_subnet_groups(identity).body['DescribeDBSubnetGroupsResult']['DBSubnetGroups'].first
          new(data) # data is an attribute hash
        rescue Fog::AWS::RDS::NotFound
          nil
        end
      end
    end
  end
end
