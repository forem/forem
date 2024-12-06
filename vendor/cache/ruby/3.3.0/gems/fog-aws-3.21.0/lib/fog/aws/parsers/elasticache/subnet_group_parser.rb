module Fog
  module Parsers
    module AWS
      module Elasticache
        class SubnetGroupParser < Fog::Parsers::Base
          def reset
            @cache_subnet_group = fresh_subnet_group
          end

          def start_element(name, attrs = [])
            super
          end

          def end_element(name)
            case name
            when 'VpcId' then @cache_subnet_group['VpcId'] = value
            when 'SubnetGroupStatus' then @cache_subnet_group['SubnetGroupStatus'] = value
            when 'CacheSubnetGroupDescription' then @cache_subnet_group['CacheSubnetGroupDescription'] = value
            when 'CacheSubnetGroupName' then @cache_subnet_group['CacheSubnetGroupName'] = value
            when 'SubnetIdentifier' then @cache_subnet_group['Subnets'] << value
            when 'Marker'
              @response['DescribeCacheSubnetGroupsResult']['Marker'] = value
            when 'RequestId'
              @response['ResponseMetadata'][name] = value
            end
          end

          def fresh_subnet_group
            {'Subnets' => []}
          end
        end
      end
    end
  end
end
