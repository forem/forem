module Fog
  module AWS
    class SNS
      class Real
        require 'fog/aws/parsers/sns/set_topic_attributes'

        # Set attributes of a topic
        #
        # ==== Parameters
        # * arn<~Hash> - The Arn of the topic to get attributes for
        # * attribute_name<~String> - Name of attribute to set, in ['DisplayName', 'Policy']
        # * attribute_value<~String> - Value to set attribute to
        #
        # ==== See Also
        # http://docs.amazonwebservices.com/sns/latest/api/API_SetTopicAttributes.html
        #

        def set_topic_attributes(arn, attribute_name, attribute_value)
          request({
            'Action'          => 'SetTopicAttributes',
            'AttributeName'   => attribute_name,
            'AttributeValue'  => attribute_value,
            'TopicArn'        => arn.strip,
            :parser     => Fog::Parsers::AWS::SNS::SetTopicAttributes.new
          })
        end
      end

      class Mock
        def set_topic_attributes(arn, attribute_name, attribute_value)
          attributes = self.data[:topics][arn]

          if %w(Policy DisplayName DeliveryPolicy).include?(attribute_name)
            attributes[attribute_name] = attribute_value
            self.data[:topics][arn] = attributes
          end

          response = Excon::Response.new
          response.body = {"RequestId" => Fog::AWS::Mock.request_id}
          response
        end
      end
    end
  end
end
