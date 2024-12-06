module Fog
  module AWS
    class SNS
      class Real
        require 'fog/aws/parsers/sns/list_subscriptions'

        # List subscriptions for a topic
        #
        # ==== Parameters
        # * arn<~String> - Arn of topic to list subscriptions for
        # * options<~Hash>:
        #   * 'NextToken'<~String> - Token returned from previous request, used for pagination
        #
        # ==== See Also
        # http://docs.amazonwebservices.com/sns/latest/api/API_ListSubscriptionsByTopic.html
        #

        def list_subscriptions_by_topic(arn, options = {})
          request({
            'Action'    => 'ListSubscriptionsByTopic',
            'TopicArn'  => arn.strip,
            :parser     => Fog::Parsers::AWS::SNS::ListSubscriptions.new
          }.merge!(options))
        end
      end

      class Mock
        def list_subscriptions_by_topic(arn, options={})
          response = Excon::Response.new

          subscriptions = self.data[:subscriptions].values.select { |s| s["TopicArn"] == arn }

          response.body = {'Subscriptions' => subscriptions, 'RequestId' => Fog::AWS::Mock.request_id}
          response
        end
      end
    end
  end
end
