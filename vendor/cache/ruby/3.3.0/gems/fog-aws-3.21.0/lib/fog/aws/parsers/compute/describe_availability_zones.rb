module Fog
  module Parsers
    module AWS
      module Compute
        class DescribeAvailabilityZones < Fog::Parsers::Base
          def start_element(name, attrs = [])
            case name
            when 'messageSet'
              @in_message_set = true
            end
            super
          end

          def reset
            @availability_zone = { 'messageSet' => [] }
            @response = { 'availabilityZoneInfo' => [] }
          end

          def end_element(name)
            case name
            when 'item'
              unless @in_message_set
                @response['availabilityZoneInfo'] << @availability_zone
                @availability_zone = { 'messageSet' => [] }
              end
            when 'message'
              @availability_zone['messageSet'] << value
            when 'regionName', 'zoneName', 'zoneState'
              @availability_zone[name] = value
            when 'requestId'
              @response[name] = value
            when 'messageSet'
              @in_message_set = false
            end
          end
        end
      end
    end
  end
end
