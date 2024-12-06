module Fog
  module AWS
    class SNS
      class Topic < Fog::Model
        identity :id, :aliases => "TopicArn"

        attribute :owner,                     :aliases => "Owner"
        attribute :policy,                    :aliases => "Policy"
        attribute :display_name,              :aliases => "DisplayName"
        attribute :subscriptions_pending,     :aliases => "SubscriptionsPending"
        attribute :subscriptions_confirmed,   :aliases => "SubscriptionsConfirmed"
        attribute :subscriptions_deleted,     :aliases => "SubscriptionsDeleted"
        attribute :delivery_policy,           :aliases => "DeliveryPolicy"
        attribute :effective_delivery_policy, :aliases => "EffectiveDeliveryPolicy"

        def ready?
          display_name
        end

        def update_topic_attribute(attribute, new_value)
          requires :id
          service.set_topic_attributes(id, attribute, new_value).body
          reload
        end

        def destroy
          requires :id
          service.delete_topic(id)
          true
        end

        def save
          requires :id

          data = service.create_topic(id).body["TopicArn"]
          if data
            data = {"id" => data}
            merge_attributes(data)
            true
          else false
          end
        end
      end
    end
  end
end
