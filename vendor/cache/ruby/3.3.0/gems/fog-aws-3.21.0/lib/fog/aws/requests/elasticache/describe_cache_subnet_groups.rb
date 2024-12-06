module Fog
  module AWS
    class Elasticache
      class Real
        require 'fog/aws/parsers/elasticache/describe_cache_subnet_groups'

        # This API returns a list of CacheSubnetGroup descriptions. If a CacheSubnetGroupName is specified, the list will contain only
        # the descriptions of the specified CacheSubnetGroup
        # http://docs.aws.amazon.com/AmazonElastiCache/latest/APIReference/API_DescribeCacheSubnetGroups.html
        # ==== Parameters
        # * CacheSubnetGroupName <~String> - The name of a specific database subnet group to return details for.
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        def describe_cache_subnet_groups(name = nil, opts = {})
          params = {}
          if opts[:marker]
            params['Marker'] = opts[:marker]
          end
          if name
            params['CacheSubnetGroupName'] = name
          end
          if opts[:max_records]
            params['MaxRecords'] = opts[:max_records]
          end

          request({
            'Action'  => 'DescribeCacheSubnetGroups',
            :parser   => Fog::Parsers::AWS::Elasticache::DescribeCacheSubnetGroups.new
          }.merge(params))
        end
      end

      class Mock
        def describe_cache_subnet_groups(name = nil, opts = {})
          response = Excon::Response.new

          subnet_group_set = []
          if name
            if subnet_group = self.data[:subnet_groups][name]
              subnet_group_set << subnet_group
            else
              raise Fog::AWS::Elasticache::NotFound.new("Subnet Group #{name} not found")
            end
          else
            subnet_group_set = self.data[:subnet_groups].values
          end

          response.status = 200
          response.body = {
            "ResponseMetadata"=>{ "RequestId"=> Fog::AWS::Mock.request_id },
            "DescribeCacheSubnetGroupsResult" => { "CacheSubnetGroups" => subnet_group_set }
          }
          response
        end
      end
    end
  end
end
