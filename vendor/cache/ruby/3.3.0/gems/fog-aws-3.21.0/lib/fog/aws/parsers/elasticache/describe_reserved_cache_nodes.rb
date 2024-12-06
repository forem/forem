module Fog
  module Parsers
    module AWS
      module Elasticache
        class DescribeReservedCacheNodes < Fog::Parsers::Base
          def reset
            @reserved_node = {}
            @response = { 'ReservedCacheNodes' => [] }
          end

          def end_element(name)
            case name
            when 'ReservedCacheNodeId', 'ReservedCacheNodesOfferingId', 'CacheNodeType', 'ProductDescription', 'State'
              @reserved_node[name] = @value
            when 'Duration', 'CacheNodeCount'
              @reserved_node[name] = @value.to_i
            when 'FixedPrice', 'UsagePrice'
              @reserved_node[name] = @value.to_f
            when 'ReservedCacheNode'
              @response['ReservedCacheNodes'] << @reserved_node
              @reserved_node = {}
            when 'Marker'
              @response[name] = @value
            when 'StartTime'
              @reserved_node[name] = Time.parse(@value)
            end
          end
        end
      end
    end
  end
end
