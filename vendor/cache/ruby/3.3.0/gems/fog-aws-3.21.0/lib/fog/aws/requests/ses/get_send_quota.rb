module Fog
  module AWS
    class SES
      class Real
        require 'fog/aws/parsers/ses/get_send_quota'

        # Returns the user's current activity limits.
        #
        # ==== Parameters
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'GetSendQuotaResult'<~Hash>
        #       * 'Max24HourSend' <~String>
        #       * 'MaxSendRate' <~String>
        #       * 'SentLast24Hours' <~String>
        #     * 'ResponseMetadata'<~Hash>:
        #       * 'RequestId'<~String> - Id of request
        def get_send_quota
          request({
            'Action' => 'GetSendQuota',
            :parser  => Fog::Parsers::AWS::SES::GetSendQuota.new
          })
        end
      end
    end
  end
end
