module Fog
  module Parsers
    module AWS
      module Elasticache
        require 'fog/aws/parsers/elasticache/subnet_group_parser'

        class CreateCacheSubnetGroup < Fog::Parsers::AWS::Elasticache::SubnetGroupParser
          def reset
            @response = { 'CreateCacheSubnetGroupResult' => {}, 'ResponseMetadata' => {} }
            super
          end

          def start_element(name, attrs = [])
            super
          end

          def end_element(name)
            case name
            when 'DBSubnetGroup' then
              @response['CreateCacheSubnetGroupResult']['CacheSubnetGroup'] = @cache_subnet_group
              @cache_subnet_group = fresh_subnet_group
            when 'RequestId'
              @response['ResponseMetadata'][name] = value
            else
              super
            end
          end
        end
      end
    end
  end
end
