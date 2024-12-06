module Fog
  module Parsers
    module AWS
      module Compute
        class DescribeRegions < Fog::Parsers::Base
          def reset
            @region = {}
            @response = { 'regionInfo' => [] }
          end

          def end_element(name)
            case name
            when 'item'
              @response['regionInfo'] << @region
              @region = {}
            when 'regionEndpoint', 'regionName'
              @region[name] = value
            when 'requestId'
              @response[name] = value
            end
          end
        end
      end
    end
  end
end
