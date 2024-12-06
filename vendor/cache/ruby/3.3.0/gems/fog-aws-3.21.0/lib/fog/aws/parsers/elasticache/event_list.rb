module Fog
  module Parsers
    module AWS
      module Elasticache
        require 'fog/aws/parsers/elasticache/base'

        class EventListParser < Base
          def reset
            super
            @response['Events'] = []
          end

          def start_element(name, attrs = [])
            super
            case name
            when 'Event'; then @event = {}
            end
          end

          def end_element(name)
            case name
            when 'Date'
              @event[name] = DateTime.parse(value.strip)
            when 'Message', 'SourceIdentifier', 'SourceType'
              @event[name] = value ? value.strip : name
            when 'Event'
              @response['Events'] << @event unless @event.empty?
            when 'IsTruncated', 'Marker', 'NextMarker'
              @response[name] = value
            else
              super
            end
          end
        end
      end
    end
  end
end
