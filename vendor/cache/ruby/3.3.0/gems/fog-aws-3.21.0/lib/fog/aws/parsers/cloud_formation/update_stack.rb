module Fog
  module Parsers
    module AWS
      module CloudFormation
        class UpdateStack < Fog::Parsers::Base
          def end_element(name)
            case name
            when 'RequestId', 'StackId'
              @response[name] = value
            end
          end
        end
      end
    end
  end
end
