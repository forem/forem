require 'fog/aws/models/rds/instance_option'

module Fog
  module AWS
    class RDS
      class InstanceOptions < Fog::PagedCollection
        attribute :filters
        attribute :engine
        model Fog::AWS::RDS::InstanceOption

        def initialize(attributes)
          self.filters ||= {}
          super
        end

        # This method deliberately returns only a single page of results
        def all(filters_arg = filters)
          filters.merge!(filters_arg)

          result = service.describe_orderable_db_instance_options(engine, filters).body['DescribeOrderableDBInstanceOptionsResult']
          filters[:marker] = result['Marker']
          load(result['OrderableDBInstanceOptions'])
        end
      end
    end
  end
end
