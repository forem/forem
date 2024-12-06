module Fog
  module AWS
    class SQS
      class Real
        require 'fog/aws/parsers/sqs/basic'

        # Change visibility timeout for a message
        #
        # ==== Parameters
        # * queue_url<~String> - Url of queue for message to update
        # * receipt_handle<~String> - Token from previous recieve message
        # * visibility_timeout<~Integer> - New visibility timeout in 0..43200
        #
        # ==== See Also
        # http://docs.amazonwebservices.com/AWSSimpleQueueService/latest/APIReference/Query_QueryChangeMessageVisibility.html
        #

        def change_message_visibility(queue_url, receipt_handle, visibility_timeout)
          request({
            'Action'            => 'ChangeMessageVisibility',
            'ReceiptHandle'     => receipt_handle,
            'VisibilityTimeout' => visibility_timeout,
            :parser             => Fog::Parsers::AWS::SQS::Basic.new,
            :path               => path_from_queue_url(queue_url)
          })
        end
      end

      class Mock
        def change_message_visibility(queue_url, receipt_handle, visibility_timeout)
          Excon::Response.new.tap do |response|
            if (queue = data[:queues][queue_url])
              message_id, _ = queue[:receipt_handles].find { |message_id, receipts|
                receipts.key?(receipt_handle)
              }

              if message_id
                queue[:messages][message_id]['Attributes']['VisibilityTimeout'] = visibility_timeout
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
