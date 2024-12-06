module Fog
  module Parsers
    module AWS
      module RDS
        class EventSubscriptionParser < Fog::Parsers::Base
          def reset
            @event_subscription = fresh_event_subscription
          end

          def fresh_event_subscription
            {'EventCategories'=> []}
          end

          def start_element(name, attrs = [])
            super
            case name
            when 'EventCategoriesList'
              @in_event_categories_list = true
            end
          end

          def end_element(name)
            case name
            when 'EventCategory'
              @event_subscription['EventCategories'] << value
              @in_event_categories_list = false
            when 'SubscriptionCreationTime'
              @event_subscription[name] = Time.parse(value)
            when 'Enabled', 'CustomerAwsId', 'SourceType', 'Status', 'CustSubscriptionId', 'SnsTopicArn'
              @event_subscription[name] = value
            end
          end
        end
      end
    end
  end
end
