module Fog
  module Parsers
    module AWS
      module CloudFormation
        class GetStackPolicy < Fog::Parsers::Base
          def end_element(name)
            case name
            when 'RequestId', 'StackPolicyBody'
              @response[name] = value
            end
          end
        end
      end
    end
  end
end
