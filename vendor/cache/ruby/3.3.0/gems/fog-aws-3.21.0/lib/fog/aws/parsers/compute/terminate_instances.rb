module Fog
  module Parsers
    module AWS
      module Compute
        class TerminateInstances < Fog::Parsers::Base
          def reset
            @instance = { 'previousState' => {}, 'currentState' => {} }
            @response = { 'instancesSet' => [] }
          end

          def start_element(name, attrs = [])
            super
            if name == 'previousState'
              @in_previous_state = true
            elsif name == 'currentState'
              @in_current_state = true
            end
          end

          def end_element(name)
            case name
            when 'instanceId'
              @instance[name] = value
            when 'item'
              @response['instancesSet'] << @instance
              @instance = { 'previousState' => {}, 'currentState' => {} }
            when 'code'
              if @in_previous_state
                @instance['previousState'][name] = value.to_i
              elsif @in_current_state
                @instance['currentState'][name] = value.to_i
              end
            when 'name'
              if @in_previous_state
                @instance['previousState'][name] = value
              elsif @in_current_state
                @instance['currentState'][name] = value
              end
            when 'previousState'
              @in_previous_state = false
            when 'requestId'
              @response[name] = value
            when 'currentState'
              @in_current_state = false
            end
          end
        end
      end
    end
  end
end
