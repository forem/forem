module Fog
  module AWS
    class SNS
      class Real
        require 'fog/aws/parsers/sns/create_topic'

        # Create a topic
        #
        # ==== Parameters
        # * name<~String> - Name of topic to create
        #
        # ==== See Also
        # http://docs.amazonwebservices.com/sns/latest/api/API_CreateTopic.html
        #

        def create_topic(name)
          request({
            'Action'  => 'CreateTopic',
            'Name'    => name,
            :parser   => Fog::Parsers::AWS::SNS::CreateTopic.new
          })
        end
      end

      class Mock
        def create_topic(name)
          response = Excon::Response.new

          topic_arn = Fog::AWS::Mock.arn(@module, @account_id, name, @region)

          self.data[:topics][topic_arn] = {
            "Owner"                   => @account_id,
            "SubscriptionsPending"    => 0,
            "SubscriptionsConfirmed"  => 0,
            "SubscriptionsDeleted"    => 0,
            "DisplayName"             => name,
            "TopicArn"                => topic_arn,
            "EffectiveDeliveryPolicy" => %Q|{"http":{"defaultHealthyRetryPolicy":{"minDelayTarget":20,"maxDelayTarget":20,"numRetries":3,"numMaxDelayRetries":0,"numNoDelayRetries":0,"numMinDelayRetries":0,"backoffFunction":"linear"},"disableSubscriptionOverrides":false}}|,
            "Policy"                  => %Q|{"Version":"2008-10-17","Id":"__default_policy_ID","Statement":[{"Sid":"__default_statement_ID","Effect":"Allow","Principal":{"AWS":"*"},"Action":["SNS:Publish","SNS:RemovePermission","SNS:SetTopicAttributes","SNS:DeleteTopic","SNS:ListSubscriptionsByTopic","SNS:GetTopicAttributes","SNS:Receive","SNS:AddPermission","SNS:Subscribe"],"Resource":"arn:aws:sns:us-east-1:990279267269:Smithy","Condition":{"StringEquals":{"AWS:SourceOwner":"990279267269"}}}]}|
          }
          self.data[:permissions][topic_arn] = {}
          response.body = {"TopicArn" => topic_arn, "RequestId" => Fog::AWS::Mock.request_id}
          response
        end
      end
    end
  end
end
