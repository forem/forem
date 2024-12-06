module Fog
  module AWS
    class SNS
      class Real
        require 'fog/aws/parsers/sns/subscribe'

        # Create a subscription
        #
        # ==== Parameters
        # * arn<~String> - Arn of topic to subscribe to
        # * endpoint<~String> - Endpoint to notify
        # * protocol<~String> - Protocol to notify endpoint with, in ['email', 'email-json', 'http', 'https', 'sqs']
        #
        # ==== See Also
        # http://docs.amazonwebservices.com/sns/latest/api/API_Subscribe.html
        #

        def subscribe(arn, endpoint, protocol)
          request({
            'Action'    => 'Subscribe',
            'Endpoint'  => endpoint,
            'Protocol'  => protocol,
            'TopicArn'  => arn.strip,
            :parser     => Fog::Parsers::AWS::SNS::Subscribe.new
          })
        end
      end

      class Mock
        def subscribe(arn, endpoint, protocol)
          response = Excon::Response.new

          unless topic = self.data[:topics][arn]
            response.status = 400
            response.body = {
              'Code'    => 'InvalidParameterValue',
              'Message' => 'Invalid parameter: TopicArn',
              'Type'    => 'Sender',
            }

            return response
          end

          subscription_arn = Fog::AWS::Mock.arn(@module, @account_id, "#{topic["DisplayName"]}:#{Fog::AWS::Mock.request_id}", @region)

          self.data[:subscriptions][subscription_arn] = {
            "Protocol"        => protocol,
            "Owner"           => @account_id.to_s,
            "TopicArn"        => arn,
            "SubscriptionArn" => subscription_arn,
            "Endpoint"        => endpoint,
          }

          mock_data = Fog::AWS::SQS::Mock.data.values.find { |a| a.values.find { |d| d[:queues][endpoint] } }
          access_key = mock_data && mock_data.keys.first

          if protocol == "sqs" && access_key
            token     = SecureRandom.hex(128)
            message   = "You have chosen to subscribe to the topic #{arn}.\nTo confirm the subscription, visit the SubscribeURL included in this message."
            signature = Fog::HMAC.new("sha256", token).sign(message)

            Fog::AWS::SQS.new(
              :region                => self.region,
              :aws_access_key_id     => access_key,
              :aws_secret_access_key => SecureRandom.hex(3)
            ).send_message(endpoint, Fog::JSON.encode(
                "Type"             => "SubscriptionConfirmation",
                "MessageId"        => UUID.uuid,
                "Token"            => token,
                "TopicArn"         => arn,
                "Message"          => message,
                "SubscribeURL"     => "https://sns.#{self.region}.amazonaws.com/?Action=ConfirmSubscription&TopicArn=#{arn}&Token=#{token}",
                "Timestamp"        => Time.now.iso8601,
                "SignatureVersion" => "1",
                "Signature"        => signature,
                "SigningCertURL"   => "https://sns.#{self.region}.amazonaws.com/SimpleNotificationService-#{SecureRandom.hex(16)}.pem"
              ))
          end

          response.body = { 'SubscriptionArn' => 'pending confirmation', 'RequestId' => Fog::AWS::Mock.request_id }
          response
        end
      end
    end
  end
end
