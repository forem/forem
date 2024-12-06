module Fog
  module Parsers
    module AWS
      module CloudFormation
        class Basic < Fog::Parsers::Base
          def end_element(name)
            case name
            when 'RequestId'
              @response[name] = value
            when 'NextToken'
              @response[name] = value
            end
          end
        end
      end
    end
  end
end
