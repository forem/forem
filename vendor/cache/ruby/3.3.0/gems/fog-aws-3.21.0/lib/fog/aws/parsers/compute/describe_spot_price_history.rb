module Fog
  module Parsers
    module AWS
      module Compute
        class DescribeSpotPriceHistory < Fog::Parsers::Base
          def reset
            @spot_price = {}
            @response = { 'spotPriceHistorySet' => [] }
          end

          def end_element(name)
            case name
            when 'availabilityZone', 'instanceType', 'productDescription'
              @spot_price[name] = value
            when 'item'
              @response['spotPriceHistorySet'] << @spot_price
              @spot_price = {}
            when 'requestId', 'nextToken'
              @response[name] = value
            when 'spotPrice'
              @spot_price[name] = value.to_f
            when 'timestamp'
              @spot_price[name] = Time.parse(value)
            end
          end
        end
      end
    end
  end
end
