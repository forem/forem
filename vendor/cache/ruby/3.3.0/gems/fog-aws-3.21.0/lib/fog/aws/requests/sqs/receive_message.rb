module Fog
  module AWS
    class SQS
      class Real
        require 'fog/aws/parsers/sqs/receive_message'

        # Get a message from a queue (marks it as unavailable temporarily, but does not remove from queue, see delete_message)
        #
        # ==== Parameters
        # * queue_url<~String> - Url of queue to get message from
        # * options<~Hash>:
        #   * Attributes<~Array> - List of attributes to return, in ['All', 'ApproximateFirstReceiveTimestamp', 'ApproximateReceiveCount', 'SenderId', 'SentTimestamp'], defaults to 'All'
        #   * MaxNumberOfMessages<~Integer> - Maximum number of messages to return, defaults to 1
        #   * VisibilityTimeout<~Integer> - Duration, in seconds, to hide message from other receives. In 0..43200, defaults to visibility timeout for queue
        #
        # ==== See Also
        # http://docs.amazonwebservices.com/AWSSimpleQueueService/latest/APIReference/Query_QueryReceiveMessage.html
        #

        def receive_message(queue_url, options = {})
          request({
            'Action'        => 'ReceiveMessage',
            'AttributeName' => 'All',
            :path           => path_from_queue_url(queue_url),
            :parser         => Fog::Parsers::AWS::SQS::ReceiveMessage.new
          }.merge!(options))
        end
      end

      class Mock
        def receive_message(queue_url, options = {})
          Excon::Response.new.tap do |response|
            if (queue = data[:queues][queue_url])
              max_number_of_messages = options['MaxNumberOfMessages'] || 1
              now = Time.now

              messages = []

              queue[:messages].values.each do |m|
                message_id = m['MessageId']

                invisible = if (received_handles = queue[:receipt_handles][message_id])
                  visibility_timeout = m['Attributes']['VisibilityTimeout'] || queue['Attributes']['VisibilityTimeout']
                  received_handles.any? { |handle, time| now < time + visibility_timeout }
                else
                  false
                end

                unless invisible
                  receipt_handle = Fog::Mock.random_base64(300)

                  queue[:receipt_handles][message_id] ||= {}
                  queue[:receipt_handles][message_id][receipt_handle] = now

                  m['Attributes'].tap do |attrs|
                    attrs['ApproximateFirstReceiveTimestamp'] ||= now
                    attrs['ApproximateReceiveCount'] = (attrs['ApproximateReceiveCount'] || 0) + 1
                  end

                  messages << m.merge({
                    'ReceiptHandle' => receipt_handle
                  })
                  break if messages.size >= max_number_of_messages
                end
              end

              response.body = {
                'ResponseMetadata' => {
                  'RequestId' => Fog::AWS::Mock.request_id
                },
                'Message' => messages
              }
              response.status = 200
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
