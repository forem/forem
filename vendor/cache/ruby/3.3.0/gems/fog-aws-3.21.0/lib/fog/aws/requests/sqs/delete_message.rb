module Fog
  module AWS
    class SQS
      class Real
        require 'fog/aws/parsers/sqs/basic'

        # Delete a message from a queue
        #
        # ==== Parameters
        # * queue_url<~String> - Url of queue to delete message from
        # * receipt_handle<~String> - Token from previous recieve message
        #
        # ==== See Also
        # http://docs.amazonwebservices.com/AWSSimpleQueueService/latest/APIReference/Query_QueryDeleteMessage.html
        #

        def delete_message(queue_url, receipt_handle)
          request({
            'Action'        => 'DeleteMessage',
            'ReceiptHandle' => receipt_handle,
            :parser         => Fog::Parsers::AWS::SQS::Basic.new,
            :path           => path_from_queue_url(queue_url),
          })
        end
      end

      class Mock
        def delete_message(queue_url, receipt_handle)
          Excon::Response.new.tap do |response|
            if (queue = data[:queues][queue_url])
              message_id, _ = queue[:receipt_handles].find { |msg_id, receipts|
                receipts.key?(receipt_handle)
              }

              if message_id
                queue[:receipt_handles].delete(message_id)
                queue[:messages].delete(message_id)
                queue['Attributes']['LastModifiedTimestamp'] = Time.now
              end

              response.body = {
                'ResponseMetadata' => {
                  'RequestId' => Fog::AWS::Mock.request_id
                }
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
