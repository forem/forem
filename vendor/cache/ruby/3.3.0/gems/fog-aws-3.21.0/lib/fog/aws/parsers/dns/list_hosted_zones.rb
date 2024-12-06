module Fog
  module Parsers
    module AWS
      module DNS
        class ListHostedZones < Fog::Parsers::Base
          def reset
            @hosted_zones = []
            @zone = {}
            @response = {}
          end

          def end_element(name)
            case name
            when 'Id'
              @zone[name] = value.sub('/hostedzone/', '')
            when 'Name', 'CallerReference', 'Comment', 'PrivateZone'
              @zone[name] = value
            when 'ResourceRecordSetCount'
              @zone['ResourceRecordSetCount'] = value.to_i
            when 'HostedZone'
              @hosted_zones << @zone
              @zone = {}
            when 'HostedZones'
              @response['HostedZones'] = @hosted_zones
            when 'MaxItems'
              @response[name] = value.to_i
            when 'IsTruncated', 'Marker', 'NextMarker'
              @response[name] = value
            end
          end
        end
      end
    end
  end
end
