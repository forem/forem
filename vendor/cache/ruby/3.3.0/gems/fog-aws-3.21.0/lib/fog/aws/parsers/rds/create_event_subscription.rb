module Fog
  module Parsers
    module AWS
      module RDS
        require 'fog/aws/parsers/rds/event_subscription_parser'

        class CreateEventSubscription < Fog::Parsers::AWS::RDS::EventSubscriptionParser
          def reset
            @response = { 'CreateEventSubscriptionResult' => {}, 'ResponseMetadata' => {} }
            @event_subscription = {}
            super
          end

          def start_element(name, attrs = [])
            super
          end

          def end_element(name)
            case name
            when 'EventSubscription'
              @response['CreateEventSubscriptionResult']['EventSubscription'] = @event_subscription
            when 'RequestId'
              @response['ResponseMetadata'][name] = value
            else
              super
            end
          end
        end
      end
    end
  end
end
