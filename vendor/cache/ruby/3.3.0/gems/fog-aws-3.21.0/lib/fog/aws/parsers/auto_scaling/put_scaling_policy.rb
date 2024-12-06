module Fog
  module Parsers
    module AWS
      module AutoScaling
        class PutScalingPolicy < Fog::Parsers::Base
          def reset
            @results = {}
            @response = { 'PutScalingPolicyResult' => {}, 'ResponseMetadata' => {} }
          end

          def end_element(name)
            case name
            when 'PolicyARN'
              @results[name] = value

            when 'RequestId'
              @response['ResponseMetadata'][name] = value

            when 'PutScalingPolicyResponse'
              @response['PutScalingPolicyResult'] = @results
            end
          end
        end
      end
    end
  end
end
