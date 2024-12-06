module Fog
  module AWS
    class RDS
      class EventSubscription < Fog::Model
        identity :id, :aliases => 'CustSubscriptionId'

        attribute :event_categories, :aliases => 'EventCategories', :type => :array
        attribute :source_type,      :aliases => 'SourceType'
        attribute :enabled,          :aliases => 'Enabled'
        attribute :status,           :aliases => 'Status'
        attribute :creation_time,    :aliases => 'SubscriptionCreationTime'
        attribute :sns_topic_arn,    :aliases => 'SnsTopicArn'

        def ready?
          ! ['deleting', 'creating'].include?(status)
        end

        def destroy
          service.delete_event_subscription(id)
          reload
        end

        def save
          requires :id, :sns_topic_arn

          data = service.create_event_subscription(
            'EventCategories'  => event_categories,
            'SourceType'       => source_type,
            'Enabled'          => enabled || true,
            'SubscriptionName' => id,
            'SnsTopicArn'      => sns_topic_arn
          ).body["CreateEventSubscriptionResult"]["EventSubscription"]
          merge_attributes(data)
          self
        end
      end
    end
  end
end
