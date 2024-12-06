module Fog
  module AWS
    class SNS
      class Real
        require 'fog/aws/parsers/sns/publish'

        # Send a message to a topic
        #
        # ==== Parameters
        # * arn<~String> - Arn of topic to send message to
        # * message<~String> - Message to send to topic
        # * options<~Hash>:
        #   * MessageStructure<~String> - message structure, in ['json']
        #   * Subject<~String> - value to use for subject when delivering by email
        #
        # ==== See Also
        # http://docs.amazonwebservices.com/sns/latest/api/API_Publish.html
        #

        def publish(arn, message, options = {})
          request({
            'Action'    => 'Publish',
            'Message'   => message,
            'TopicArn'  => arn.strip,
            :parser     => Fog::Parsers::AWS::SNS::Publish.new
          }.merge!(options))
        end
      end
    end
  end
end
