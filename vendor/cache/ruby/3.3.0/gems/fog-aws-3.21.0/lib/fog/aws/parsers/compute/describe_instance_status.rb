module Fog
  module Parsers
    module AWS
      module Compute
        class DescribeInstanceStatus < Fog::Parsers::Base
          def new_instance!
            @instance = { 'instanceState' => {}, 'systemStatus' => { 'details' => [] }, 'instanceStatus' => { 'details' => [] }, 'eventsSet' => [] }
          end

          def new_item!
            @item = {}
          end

          def reset
            @response = { 'instanceStatusSet' => [] }
            @inside = nil
          end

          def start_element(name, attrs=[])
            super
            case name
            when 'item'
              if @inside
                new_item!
              else
                new_instance!
              end
            when 'systemStatus'
              @inside = :systemStatus
            when 'instanceState'
              @inside = :instanceState
            when 'instanceStatus'
              @inside = :instanceStatus
            when 'eventsSet'
              @inside = :eventsSet
            end
          end

          def end_element(name)
            case name
            #Simple closers
            when 'instanceId', 'availabilityZone'
              @instance[name] = value
            when 'nextToken', 'requestId'
              @response[name] = value
            when 'systemStatus', 'instanceState', 'instanceStatus', 'eventsSet'
              @inside = nil
            when 'item'
              case @inside
              when :eventsSet
                @instance['eventsSet'] << @item
              when :systemStatus, :instanceStatus
                @instance[@inside.to_s]['details'] << @item
              when nil
                @response['instanceStatusSet'] << @instance
              end
              @item = nil
            when 'code'
              case @inside
              when :eventsSet
                @item[name] = value
              when :instanceState
                @instance[@inside.to_s][name] = value.to_i
              end
            when 'description', 'notBefore', 'notAfter', 'name', 'status'
              @item.nil? ? (@instance[@inside.to_s][name] = value) : (@item[name] = value)
            end
          end
        end
      end
    end
  end
end
