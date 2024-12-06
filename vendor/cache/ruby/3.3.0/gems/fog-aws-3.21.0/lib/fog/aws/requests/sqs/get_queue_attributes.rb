module Fog
  module AWS
    class SQS
      class Real
        require 'fog/aws/parsers/sqs/get_queue_attributes'

        # Get attributes of a queue
        #
        # ==== Parameters
        # * queue_url<~String> - Url of queue to get attributes for
        # * attribute_name<~Array> - Name of attribute to return, in ['All', 'ApproximateNumberOfMessages', 'ApproximateNumberOfMessagesNotVisible', 'CreatedTimestamp', 'LastModifiedTimestamp', 'MaximumMessageSize', 'MessageRetentionPeriod', 'Policy', 'QueueArn', 'VisibilityTimeout']
        #
        # ==== See Also
        # http://docs.amazonwebservices.com/AWSSimpleQueueService/latest/APIReference/Query_QueryGetQueueAttributes.html
        #

        def get_queue_attributes(queue_url, attribute_name)
          request({
            'Action'        => 'GetQueueAttributes',
            'AttributeName' => attribute_name,
            :path           => path_from_queue_url(queue_url),
            :parser         => Fog::Parsers::AWS::SQS::GetQueueAttributes.new
          })
        end
      end

      class Mock
        def get_queue_attributes(queue_url, attribute_name)
          Excon::Response.new.tap do |response|
            if (queue = data[:queues][queue_url])
              response.status = 200

              response.body = {
                'ResponseMetadata' => {
                  'RequestId' => Fog::AWS::Mock.request_id
                },
                'Attributes' => queue['Attributes']
              }
            else
              response.status = 404
              raise(Excon::Errors.status_error({:expects => 200}, response))
            end
          end
        end
      end
    end
  end
end
