module Fog
  module AWS
    class SQS
      class Real
        require 'fog/aws/parsers/sqs/create_queue'

        # Create a queue
        #
        # ==== Parameters
        # * name<~String> - Name of queue to create
        # * options<~Hash>:
        #   * DefaultVisibilityTimeout<~String> - Time, in seconds, to hide a message after it has been received, in 0..43200, defaults to 30
        #
        # ==== See Also
        # http://docs.amazonwebservices.com/AWSSimpleQueueService/latest/APIReference/Query_QueryCreateQueue.html
        #

        def create_queue(name, options = {})
          request({
            'Action'    => 'CreateQueue',
            'QueueName' => name,
            :parser     => Fog::Parsers::AWS::SQS::CreateQueue.new
          }.merge!(options))
        end
      end

      class Mock
        def create_queue(name, options = {})
          Excon::Response.new.tap do |response|
            response.status = 200

            now = Time.now
            queue_url = "https://queue.amazonaws.com/#{data[:owner_id]}/#{name}"
            queue = {
              'QueueName'      => name,
              'Attributes'     => {
                'VisibilityTimeout'                     => 30,
                'ApproximateNumberOfMessages'           => 0,
                'ApproximateNumberOfMessagesNotVisible' => 0,
                'CreatedTimestamp'                      => now,
                'LastModifiedTimestamp'                 => now,
                'QueueArn'                              => Fog::AWS::Mock.arn('sqs', 'us-east-1', data[:owner_id], name),
                'MaximumMessageSize'                    => 8192,
                'MessageRetentionPeriod'                => 345600
              },
              :messages        => {},
              :receipt_handles => {}
            }
            data[:queues][queue_url] = queue unless data[:queues][queue_url]

            response.body = {
              'ResponseMetadata' => {
                'RequestId' => Fog::AWS::Mock.request_id
              },
              'QueueUrl' => queue_url
            }
          end
        end
      end
    end
  end
end
