module Fog
  module AWS
    class SQS
      class Real
        require 'fog/aws/parsers/sqs/send_message'

        # Add a message to a queue
        #
        # ==== Parameters
        # * queue_url<~String> - Url of queue to add message to
        # * message<~String> - Message to add to queue
        #
        # ==== See Also
        # http://docs.amazonwebservices.com/AWSSimpleQueueService/latest/APIReference/Query_QuerySendMessage.html
        #

        def send_message(queue_url, message)
          request({
            'Action'      => 'SendMessage',
            'MessageBody' => message,
            :path         => path_from_queue_url(queue_url),
            :parser       => Fog::Parsers::AWS::SQS::SendMessage.new
          })
        end
      end

      class Mock
        def send_message(queue_url, message)
          Excon::Response.new.tap do |response|
            if (queue = data[:queues][queue_url])
              response.status = 200

              now        = Time.now
              message_id = Fog::AWS::Mock.sqs_message_id
              md5        = OpenSSL::Digest::MD5.hexdigest(message)

              queue[:messages][message_id] = {
                'MessageId'  => message_id,
                'Body'       => message,
                'MD5OfBody'  => md5,
                'Attributes' => {
                  'SenderId'      => Fog::AWS::Mock.sqs_message_id,
                  'SentTimestamp' => now
                }
              }

              queue['Attributes']['LastModifiedTimestamp'] = now

              response.body = {
                'ResponseMetadata' => {
                  'RequestId' => Fog::AWS::Mock.request_id
                },
                'MessageId'        => message_id,
                'MD5OfMessageBody' => md5
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
