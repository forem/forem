module Fog
  module AWS
    class SNS
      class Real
        require 'fog/aws/parsers/sns/unsubscribe'

        # Delete a subscription
        #
        # ==== Parameters
        # * arn<~String> - Arn of subscription to delete
        #
        # ==== See Also
        # http://docs.amazonwebservices.com/sns/latest/api/API_Unsubscribe.html
        #

        def unsubscribe(arn)
          request({
            'Action'          => 'Unsubscribe',
            'SubscriptionArn' => arn.strip,
            :parser           => Fog::Parsers::AWS::SNS::Unsubscribe.new
          })
        end
      end
    end
  end
end
