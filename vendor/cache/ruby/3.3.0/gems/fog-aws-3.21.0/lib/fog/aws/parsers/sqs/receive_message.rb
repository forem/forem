module Fog
  module Parsers
    module AWS
      module SQS
        class ReceiveMessage < Fog::Parsers::Base
          def reset
            @message  = { 'Attributes' => {} }
            @response = { 'ResponseMetadata' => {}, 'Message' => []}
          end

          def end_element(name)
            case name
            when 'RequestId'
              @response['ResponseMetadata']['RequestId'] = @value
            when 'Message'
              @response['Message'] << @message
              @message = { 'Attributes' => {} }
            when 'Body', 'MD5OfBody', 'MessageId', 'ReceiptHandle'
              @message[name] = @value
            when 'Name'
              @current_attribute_name = @value
            when 'Value'
              case @current_attribute_name
              when 'ApproximateFirstReceiveTimestamp', 'SentTimestamp'
                @message['Attributes'][@current_attribute_name] = Time.at(@value.to_i / 1000.0)
              when 'ApproximateReceiveCount'
                @message['Attributes'][@current_attribute_name] = @value.to_i
              else
                @message['Attributes'][@current_attribute_name] = @value
              end
            end
          end
        end
      end
    end
  end
end
