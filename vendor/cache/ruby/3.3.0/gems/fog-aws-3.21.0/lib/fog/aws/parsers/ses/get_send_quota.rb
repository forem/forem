module Fog
  module Parsers
    module AWS
      module SES
        class GetSendQuota < Fog::Parsers::Base
          def reset
            @response = { 'ResponseMetadata' => {} }
          end

          def end_element(name)
            case name
            when "Max24HourSend", "MaxSendRate", "SentLast24Hours"
              @response[name] = value
            when 'RequestId'
              @response['ResponseMetadata'][name] = value
            end
          end
        end
      end
    end
  end
end
