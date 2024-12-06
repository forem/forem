module Fog
  module Parsers
    module AWS
      module SQS
        class GetQueueAttributes < Fog::Parsers::Base
          def reset
            @response = { 'ResponseMetadata' => {}, 'Attributes' => {}}
          end

          def end_element(name)
            case name
            when 'RequestId'
              @response['ResponseMetadata']['RequestId'] = @value
            when 'Name'
              @current_attribute_name = @value
            when 'Value'
              case @current_attribute_name
              when 'ApproximateNumberOfMessages', 'ApproximateNumberOfMessagesNotVisible', 'MaximumMessageSize', 'MessageRetentionPeriod', 'VisibilityTimeout'
                @response['Attributes'][@current_attribute_name] = @value.to_i
              when 'CreatedTimestamp', 'LastModifiedTimestamp'
                @response['Attributes'][@current_attribute_name] = Time.at(@value.to_i)
              else
                @response['Attributes'][@current_attribute_name] = @value
              end
            end
          end
        end
      end
    end
  end
end
