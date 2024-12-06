require 'fog/aws/models/rds/security_group'

module Fog
  module AWS
    class RDS
      class SecurityGroups < Fog::Collection
        attribute :server
        attribute :filters
        model Fog::AWS::RDS::SecurityGroup

        def initialize(attributes={})
          self.filters ||= {}
          if attributes[:server]
            filters[:identifier] = attributes[:server].id
          end
          super
        end

        def all(filters_arg = filters)
          filters = filters_arg
          data = service.describe_db_security_groups(filters).body['DescribeDBSecurityGroupsResult']['DBSecurityGroups']
          load(data) # data is an array of attribute hashes
        end

        # Example:
        # get('my_db_security_group') # => model for my_db_security_group
        def get(identity)
          data = service.describe_db_security_groups(identity).body['DescribeDBSecurityGroupsResult']['DBSecurityGroups'].first
          new(data) # data is an attribute hash
        rescue Fog::AWS::RDS::NotFound
          nil
        end

        def new(attributes = {})
          super
        end
      end
    end
  end
end
