module Fog
  module Parsers
    module AWS
      module ELB
        class DescribeInstanceHealth < Fog::Parsers::Base
          def reset
            @response = { 'DescribeInstanceHealthResult' => { 'InstanceStates' => [] }, 'ResponseMetadata' => {} }
            @instance_state = {}
          end

          def end_element(name)
            case name
            when 'Description', 'State', 'InstanceId', 'ReasonCode'
              @instance_state[name] = value
            when 'member'
              @response['DescribeInstanceHealthResult']['InstanceStates'] << @instance_state
              @instance_state = {}
            when 'RequestId'
              @response['ResponseMetadata'][name] = value
            end
          end
        end
      end
    end
  end
end
