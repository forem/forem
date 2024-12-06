require 'fog/aws/models/sns/subscription'

module Fog
  module AWS
    class SNS
      class Subscriptions < Fog::Collection
        model Fgo::AWS::SNS::Subscription

        def all
          data = service.list_subscriptions.body["Subscriptions"]
          load(data)
        end
      end
    end
  end
end
