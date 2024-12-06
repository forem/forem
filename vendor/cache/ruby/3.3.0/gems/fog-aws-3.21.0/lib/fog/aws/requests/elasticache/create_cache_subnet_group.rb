module Fog
  module AWS
    class Elasticache
      class Real
        require 'fog/aws/parsers/elasticache/create_cache_subnet_group'

        # Creates a cache subnet group
        # http://docs.aws.amazon.com/AmazonElastiCache/latest/APIReference/API_CreateCacheSubnetGroup.html
        #
        # ==== Parameters
        # * CacheSubnetGroupName <~String> - A name for the cache subnet group. This value is stored as a lowercase string. Must contain no more than 255 alphanumeric characters or hyphens.
        # * SubnetIds <~Array> - The VPC subnet IDs for the cache subnet group.
        # * CacheSubnetGroupDescription <~String> - A description for the cache subnet group.
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        def create_cache_subnet_group(name, subnet_ids, description = name)
          params = {
            'Action' => 'CreateCacheSubnetGroup',
            'CacheSubnetGroupName' => name,
            'CacheSubnetGroupDescription' => description,
            :parser => Fog::Parsers::AWS::Elasticache::CreateCacheSubnetGroup.new
          }
          params.merge!(Fog::AWS.indexed_param("SubnetIds.member", Array(subnet_ids)))
          request(params)
        end
      end

      class Mock
        def create_cache_subnet_group(name, subnet_ids, description = name)
          response = Excon::Response.new
          if self.data[:subnet_groups] && self.data[:subnet_groups][name]
            raise Fog::AWS::Elasticache::IdentifierTaken.new("CacheSubnetGroupAlreadyExists => The subnet group '#{name}' already exists")
          end

          collection = Fog::Compute[:aws]
          collection.region = @region
          subnets = collection.subnets

          subnets = subnet_ids.map { |snid| subnets.get(snid) }
          vpc_id = subnets.first.vpc_id

          data = {
            'CacheSubnetGroupName' => name,
            'CacheSubnetGroupDescription' => description,
            'SubnetGroupStatus' => 'Complete',
            'Subnets' => subnet_ids,
            'VpcId' => vpc_id
          }
          self.data[:subnet_groups][name] = data
          response.body = {
            "ResponseMetadata"=>{ "RequestId"=> Fog::AWS::Mock.request_id },
            'CreateCacheSubnetGroupResult' => { 'CacheSubnetGroup' => data }
          }
          response
        end
      end
    end
  end
end
