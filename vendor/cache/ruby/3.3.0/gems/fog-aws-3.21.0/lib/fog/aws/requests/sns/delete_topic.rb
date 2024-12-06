module Fog
  module AWS
    class SNS
      class Real
        require 'fog/aws/parsers/sns/delete_topic'

        # Delete a topic
        #
        # ==== Parameters
        # * arn<~String> - The Arn of the topic to delete
        #
        # ==== See Also
        # http://docs.amazonwebservices.com/sns/latest/api/API_DeleteTopic.html
        #

        def delete_topic(arn)
          request({
            'Action'    => 'DeleteTopic',
            'TopicArn'  => arn.strip,
            :parser     => Fog::Parsers::AWS::SNS::DeleteTopic.new
          })
        end
      end

      class Mock
        def delete_topic(arn)
          self.data[:topics].delete(arn)

          response = Excon::Response.new
          response.body = {"RequestId" => Fog::AWS::Mock.request_id}
          response
        end
      end
    end
  end
end
