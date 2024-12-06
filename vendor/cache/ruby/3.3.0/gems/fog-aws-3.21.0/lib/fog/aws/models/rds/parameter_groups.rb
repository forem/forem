require 'fog/aws/models/rds/parameter_group'

module Fog
  module AWS
    class RDS
      class ParameterGroups < Fog::Collection
        model Fog::AWS::RDS::ParameterGroup

        def all
          data = service.describe_db_parameter_groups.body['DescribeDBParameterGroupsResult']['DBParameterGroups']
          load(data) # data is an array of attribute hashes
        end

        def get(identity)
          data = service.describe_db_parameter_groups(identity).body['DescribeDBParameterGroupsResult']['DBParameterGroups'].first
          new(data) # data is an attribute hash
        rescue Fog::AWS::RDS::NotFound
          nil
        end
      end
    end
  end
end
