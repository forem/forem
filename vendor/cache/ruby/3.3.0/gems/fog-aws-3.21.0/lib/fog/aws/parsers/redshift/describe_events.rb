module Fog
  module Parsers
    module Redshift
      module AWS
        class DescribeEvents < Fog::Parsers::Base
          # :marker - (String)
          # :events - (Array)
          #   :source_identifier - (String)
          #   :source_type - (String)
          #   :message - (String)
          #   :date - (Time)

          def reset
            @response = { 'Events' => [] }
          end

          def start_element(name, attrs = [])
            super
            case name
            when 'Events'
              @event = {}
            end
          end

          def end_element(name)
            super
            case name
            when 'Marker'
              @response[name] = value
            when 'SourceIdentifier', 'SourceType', 'Message'
              @event[name] = value
            when 'Date'
              @event[name] = Time.parse(value)
            when 'Event'
              @response['Events'] << {name => @event}
              @event = {}
            end
          end
        end
      end
    end
  end
end
