module Fog
  module AWS
    class SES
      class Real
        require 'fog/aws/parsers/ses/send_raw_email'

        # Send a raw email
        #
        # ==== Parameters
        # * RawMessage <~String> - The message to be sent.
        # * Options <~Hash>
        #   * Source <~String> - The sender's email address. Takes precenence over Return-Path if specified in RawMessage
        #   * Destinations <~Array> - All destinations for this email.
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'MessageId'<~String> - Id of message
        #     * 'ResponseMetadata'<~Hash>:
        #       * 'RequestId'<~String> - Id of request
        def send_raw_email(raw_message, options = {})
          params = {}
          if options.key?('Destinations')
            params.merge!(Fog::AWS.indexed_param('Destinations.member', [*options['Destinations']]))
          end
          if options.key?('Source')
            params['Source'] = options['Source']
          end

          request({
            'Action'          => 'SendRawEmail',
            'RawMessage.Data' => Base64.encode64(raw_message.to_s).chomp!,
            :parser           => Fog::Parsers::AWS::SES::SendRawEmail.new
          }.merge(params))
        end
      end
    end
  end
end
