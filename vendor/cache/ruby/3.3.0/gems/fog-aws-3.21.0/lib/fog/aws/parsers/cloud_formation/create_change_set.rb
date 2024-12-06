module Fog
  module Parsers
    module AWS
      module CloudFormation
        class CreateChangeSet < Fog::Parsers::Base
          def end_element(name)
            case name
            when 'RequestId', 'Id'
              @response[name] = value
            end
          end
        end
      end
    end
  end
end
