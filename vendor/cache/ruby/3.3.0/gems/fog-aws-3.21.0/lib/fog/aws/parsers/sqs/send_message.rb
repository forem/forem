module Fog
  module Parsers
    module AWS
      module SQS
        class SendMessage < Fog::Parsers::Base
          def reset
            @response = { 'ResponseMetadata' => {} }
          end

          def end_element(name)
            case name
            when 'RequestId'
              @response['ResponseMetadata'][name] = @value
            when 'MessageId'
              @response['MessageId'] = @value
            when 'MD5OfMessageBody'
              @response['MD5OfMessageBody'] = @value
            end
          end
        end
      end
    end
  end
end
