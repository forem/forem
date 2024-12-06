module Fog
  module Parsers
    module AWS
      module CloudFormation
        class GetTemplate < Fog::Parsers::Base
          def end_element(name)
            case name
            when 'RequestId', 'TemplateBody'
              @response[name] = value
            end
          end
        end
      end
    end
  end
end
