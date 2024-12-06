module Fog
  module AWS
    class RDS
      class Real
        require 'fog/aws/parsers/rds/describe_db_subnet_groups'

        # This API returns a list of DBSubnetGroup descriptions. If a DBSubnetGroupName is specified, the list will contain only
        # the descriptions of the specified DBSubnetGroup
        # http://docs.amazonwebservices.com/AmazonRDS/2012-01-15/APIReference/API_DescribeDBSubnetGroups.html
        # ==== Parameters
        # * DBSubnetGroupName <~String> - The name of a specific database subnet group to return details for.
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        def describe_db_subnet_groups(name = nil, opts = {})
          params = {}
          if opts[:marker]
            params['Marker'] = opts[:marker]
          end
          if name
            params['DBSubnetGroupName'] = name
          end
          if opts[:max_records]
            params['MaxRecords'] = opts[:max_records]
          end

          request({
            'Action'  => 'DescribeDBSubnetGroups',
            :parser   => Fog::Parsers::AWS::RDS::DescribeDBSubnetGroups.new
          }.merge(params))
        end
      end

      class Mock
        def describe_db_subnet_groups(name = nil, opts = {})
          response = Excon::Response.new

          subnet_group_set = []
          if name
            if subnet_group = self.data[:subnet_groups][name]
              subnet_group_set << subnet_group
            else
              raise Fog::AWS::RDS::NotFound.new("Subnet Group #{name} not found")
            end
          else
            subnet_group_set = self.data[:subnet_groups].values
          end

          response.status = 200
          response.body = {
            "ResponseMetadata"=>{ "RequestId"=> Fog::AWS::Mock.request_id },
            "DescribeDBSubnetGroupsResult" => { "DBSubnetGroups" => subnet_group_set }
          }
          response
        end
      end
    end
  end
end
