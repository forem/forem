module Fog
  module Parsers
    module AWS
      module SNS
        class Publish < Fog::Parsers::Base
          def reset
            @response = {}
          end

          def end_element(name)
            case name
            when 'MessageId', 'RequestId'
              @response[name] = @value.rstrip
            end
          end
        end
      end
    end
  end
end
