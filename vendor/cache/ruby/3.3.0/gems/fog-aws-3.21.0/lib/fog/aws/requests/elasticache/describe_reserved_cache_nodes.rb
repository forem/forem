module Fog
  module AWS
    class Elasticache
      class Real
        require 'fog/aws/parsers/elasticache/describe_reserved_cache_nodes'

        # Describe all or specified reserved Elasticache nodes
        # http://docs.aws.amazon.com/AmazonElastiCache/latest/APIReference/API_DescribeReservedCacheNodes.html
        # ==== Parameters
        # * ReservedCacheNodeId <~String> - ID of node to retrieve information for. If absent, information for all nodes is returned.
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        def describe_reserved_cache_nodes(identifier=nil, opts={})
          params = {}
          params['ReservedCacheNodeId'] = identifier if identifier
          if opts[:marker]
            params['Marker'] = opts[:marker]
          end
          if opts[:max_records]
            params['MaxRecords'] = opts[:max_records]
          end

          request({
            'Action'  => 'DescribeReservedCacheNodes',
            :parser   => Fog::Parsers::AWS::Elasticache::DescribeReservedCacheNodes.new
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
