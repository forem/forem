module Fog
  module Parsers
    module AWS
      module RDS
        require 'fog/aws/parsers/rds/event_subscription_parser'

        class DescribeEventSubscriptions < Fog::Parsers::AWS::RDS::EventSubscriptionParser
          def reset
            @response = { 'DescribeEventSubscriptionsResult' => { 'EventSubscriptionsList' => []}, 'ResponseMetadata' => {} }
            super
          end

          def start_element(name, attrs = [])
            super
          end

          def end_element(name)
            case name
            when 'EventSubscription'
              @response['DescribeEventSubscriptionsResult']['EventSubscriptionsList'] << @event_subscription
              @event_subscription = fresh_event_subscription
            when 'Marker'
              @response['DescribeEventSubscriptionsResult']['Marker'] = value
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
