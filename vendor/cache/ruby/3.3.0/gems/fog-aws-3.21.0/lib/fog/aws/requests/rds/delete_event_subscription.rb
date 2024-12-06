module Fog
  module AWS
    class RDS
      class Real
        require 'fog/aws/parsers/rds/delete_event_subscription'

        # deletes an event subscription
        # http://docs.aws.amazon.com/AmazonRDS/latest/APIReference/API_DeleteEventSubscription.html
        # === Parameters
        # * SubscriptionName <~String> - The name of the subscription to delete
        # === Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>

        def delete_event_subscription(name)
          request({
            'Action'           => 'DeleteEventSubscription',
            'SubscriptionName' => name,
            :parser            => Fog::Parsers::AWS::RDS::DeleteEventSubscription.new
          })
        end
      end

      class Mock
        def delete_event_subscription(name)
          response = Excon::Response.new

          if data = self.data[:event_subscriptions][name]
            data['Status'] = 'deleting'
            self.data[:event_subscriptions][name] = data

            response.status = 200
            response.body = {
              "ResponseMetadata"=>{ "RequestId"=> Fog::AWS::Mock.request_id },
            }
            response
          else
            raise Fog::AWS::RDS::NotFound.new("EventSubscriptionNotFound => #{name} not found")
          end
        end
      end
    end
  end
end
