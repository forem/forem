module Fog
  module Parsers
    module AWS
      module Compute
        class DescribeVolumeStatus < Fog::Parsers::Base
          def reset
            @action_set = {}
            @detail = {}
            @event_set = {}
            @volume_status = { 'details' => [] }
            @volume = { 'actionsSet' => [], 'eventsSet' => [] }
            @response = { 'volumeStatusSet' => [] }
          end

          def start_element(name, attrs=[])
            super
            case name
            when 'actionsSet'
              @in_actions_set = true
            when 'details'
              @in_details = true
            when 'eventsSet'
              @in_events_set = true
            when 'volumeStatus'
              @in_volume_status = true
            end
          end

          def end_element(name)
            if @in_actions_set
              case name
              when 'actionsSet'
                @in_actions_set = false
              when 'code', 'eventId', 'eventType', 'description'
                @action_set[name] = value.strip
              when 'item'
                @volume['actionsSet'] << @action_set
                @action_set = {}
              end
            elsif @in_details
              case name
              when 'details'
                @in_details = false
              when 'name', 'status'
                @detail[name] = value
              when 'item'
                @volume_status['details'] << @detail
                @detail = {}
              end
            elsif @in_events_set
              case name
              when 'eventsSet'
                @in_events_set = false
              when 'code', 'eventId', 'eventType', 'description'
                @event_set[name] = value.strip
              when 'notAfter', 'notBefore'
                @event_set[name] = Time.parse(value)
              when 'item'
                @volume['eventsSet'] << @event_set
                @event_set = {}
              end
            elsif @in_volume_status
              case name
              when 'volumeStatus'
                @volume['volumeStatus'] = @volume_status
                @volume_status = { 'details' => [] }
                @in_volume_status = false
              when 'status'
                @volume_status[name] = value
              end
            else
              case name
              when 'volumeId', 'availabilityZone'
                @volume[name] = value
              when 'nextToken', 'requestId'
                @response[name] = value
              when 'item'
                @response['volumeStatusSet'] << @volume
                @volume = { 'actionsSet' => [], 'eventsSet' => [] }
              end
            end
          end
        end
      end
    end
  end
end
