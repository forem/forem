module Fog
  module AWS
    class SNS
      class Real
        require 'fog/aws/parsers/sns/confirm_subscription'

        # Confirm a subscription
        #
        # ==== Parameters
        # * arn<~String> - Arn of topic to confirm subscription to
        # * token<~String> - Token sent to endpoint during subscribe action
        # * options<~Hash>:
        #   * AuthenticateOnUnsubscribe<~Boolean> - whether or not unsubscription should be authenticated, defaults to false
        #
        # ==== See Also
        # http://docs.amazonwebservices.com/sns/latest/api/API_ConfirmSubscription.html
        #

        def confirm_subscription(arn, token, options = {})
          request({
            'Action'    => 'ConfirmSubscription',
            'Token'     => token,
            'TopicArn'  => arn.strip,
            :parser     => Fog::Parsers::AWS::SNS::ConfirmSubscription.new
          }.merge!(options))
        end
      end
    end
  end
end
