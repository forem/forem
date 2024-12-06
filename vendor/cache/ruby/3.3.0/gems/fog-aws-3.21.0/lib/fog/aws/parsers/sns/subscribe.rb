module Fog
  module Parsers
    module AWS
      module SNS
        class Subscribe < Fog::Parsers::Base
          def reset
            @response = {}
          end

          def end_element(name)
            case name
            when 'SubscriptionArn', 'RequestId'
              @response[name] = @value.strip
            end
          end
        end
      end
    end
  end
end
