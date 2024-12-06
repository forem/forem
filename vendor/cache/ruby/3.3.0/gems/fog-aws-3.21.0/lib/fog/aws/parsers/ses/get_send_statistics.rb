module Fog
  module Parsers
    module AWS
      module SES
        class GetSendStatistics < Fog::Parsers::Base
          def reset
            @response = { 'SendDataPoints' => [], 'ResponseMetadata' => {} }
            @send_data_point = {}
          end

          def end_element(name)
            case name
            when "Bounces", "Complaints", "DeliveryAttempts", "Rejects", "Timestamp"
              @send_data_point[name] = value
            when 'member'
              @response['SendDataPoints'] << @send_data_point
              @send_data_point = {}
            when 'RequestId'
              @response['ResponseMetadata'][name] = value
            end
          end
        end
      end
    end
  end
end
