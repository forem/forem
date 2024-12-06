require 'fog/aws/models/rds/event_subscription'

module Fog
  module AWS
    class RDS
      class EventSubscriptions < Fog::Collection
        model Fog::AWS::RDS::EventSubscription

        def all
          data = service.describe_event_subscriptions.body['DescribeEventSubscriptionsResult']['EventSubscriptionsList']
          load(data)
        end

        def get(identity)
          data = service.describe_event_subscriptions('SubscriptionName' => identity).body['DescribeEventSubscriptionsResult']['EventSubscriptionsList']
          new(data.first)
        rescue Fog::AWS::RDS::NotFound
          nil
        end
      end
    end
  end
end
