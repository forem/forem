module Fog
  module Parsers
    module AWS
      module SNS
        class CreateTopic < Fog::Parsers::Base
          def reset
            @response = {}
          end

          def end_element(name)
            case name
            when 'TopicArn', 'RequestId'
              @response[name] = @value.strip
            end
          end
        end
      end
    end
  end
end
