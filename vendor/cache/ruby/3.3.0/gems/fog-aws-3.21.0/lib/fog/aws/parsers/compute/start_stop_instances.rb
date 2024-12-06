module Fog
  module Parsers
    module AWS
      module Compute
        class StartStopInstances < Fog::Parsers::Base
          def reset
            @instance = { 'currentState' => {}, 'previousState' => {} }
            @response = { 'instancesSet' => [] }
            @state = nil
          end

          def start_element(name, attrs = [])
            super
            case name
            when 'currentState', 'previousState'
              @state = name
            end
          end

          def end_element(name)
            case name
            when 'code'
              @instance[@state][name] = value.to_s
            when 'instanceId'
              @instance[name] = value
            when 'item'
              @response['instancesSet'] << @instance
              @instance = { 'currentState' => {}, 'previousState' => {} }
            when 'name'
              @instance[@state][name] = value
            end
          end
        end
      end
    end
  end
end
