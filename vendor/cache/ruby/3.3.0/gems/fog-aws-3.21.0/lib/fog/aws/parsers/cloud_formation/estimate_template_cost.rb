module Fog
  module Parsers
    module AWS
      module CloudFormation
        class EstimateTemplateCost < Fog::Parsers::Base
          def end_element(name)
            case name
            when 'RequestId', 'Url'
              @response[name] = value
            end
          end
        end
      end
    end
  end
end
