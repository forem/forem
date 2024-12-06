module Fog
  module Parsers
    module AWS
      module SNS
        class ListSubscriptions < Fog::Parsers::Base
          def reset
            @response = { 'Subscriptions' => [] }
            @subscription = {}
          end

          def end_element(name)
            case name
            when "TopicArn", "Protocol", "SubscriptionArn", "Owner", "Endpoint"
              @subscription[name] = @value.strip
            when "member"
              @response['Subscriptions'] << @subscription
              @subscription = {}
            when 'RequestId', 'NextToken'
              @response[name] = @value.strip
            end
          end
        end
      end
    end
  end
end
