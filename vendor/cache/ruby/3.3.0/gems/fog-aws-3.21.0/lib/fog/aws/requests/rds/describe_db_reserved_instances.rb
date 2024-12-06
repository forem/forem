module Fog
  module AWS
    class RDS
      class Real
        require 'fog/aws/parsers/rds/describe_db_reserved_instances'

        # Describe all or specified load db instances
        # http://docs.amazonwebservices.com/AmazonRDS/latest/APIReference/API_DescribeDBInstances.html
        # ==== Parameters
        # * DBInstanceIdentifier <~String> - ID of instance to retrieve information for. if absent information for all instances is returned
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        def describe_db_reserved_instances(identifier=nil, opts={})
          params = {}
          params['ReservedDBInstanceId'] = identifier if identifier
          if opts[:marker]
            params['Marker'] = opts[:marker]
          end
          if opts[:max_records]
            params['MaxRecords'] = opts[:max_records]
          end

          request({
            'Action'  => 'DescribeReservedDBInstances',
            :parser   => Fog::Parsers::AWS::RDS::DescribeDBReservedInstances.new
          }.merge(params))
        end
      end

      class Mock
        def describe_db_reserved_instances(identifier=nil, opts={})
          Fog::Mock.not_implemented
        end
      end
    end
  end
end
