module Fog
  module Parsers
    module AWS
      module EMR
        class RunJobFlow < Fog::Parsers::Base
          def end_element(name)
            case name
            when 'JobFlowId'
              @response[name] = value
            when 'RequestId'
              @response[name] = value
            end
          end
        end
      end
    end
  end
end
