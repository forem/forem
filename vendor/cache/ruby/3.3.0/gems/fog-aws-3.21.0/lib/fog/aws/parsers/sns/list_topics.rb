module Fog
  module Parsers
    module AWS
      module SNS
        class ListTopics < Fog::Parsers::Base
          def reset
            @response = { 'Topics' => [] }
          end

          def end_element(name)
            case name
            when 'TopicArn'
              @response['Topics'] << @value.strip
            when 'NextToken', 'RequestId'
              response[name] = @value
            end
          end
        end
      end
    end
  end
end
