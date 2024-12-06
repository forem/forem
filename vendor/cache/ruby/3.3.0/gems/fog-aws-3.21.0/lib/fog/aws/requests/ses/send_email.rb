module Fog
  module AWS
    class SES
      class Real
        require 'fog/aws/parsers/ses/send_email'

        # Send an email
        #
        # ==== Parameters
        # * Source <~String> - The sender's email address
        # * Destination <~Hash> - The destination for this email, composed of To:, From:, and CC: fields.
        #   * BccAddresses <~Array> - The BCC: field(s) of the message.
        #   * CcAddresses <~Array> - The CC: field(s) of the message.
        #   * ToAddresses <~Array> - The To: field(s) of the message.
        # * Message <~Hash> - The message to be sent.
        #   * Body <~Hash>
        #     * Html <~Hash>
        #       * Charset <~String>
        #       * Data <~String>
        #     * Text <~Hash>
        #       * Charset <~String>
        #       * Data <~String>
        #   * Subject <~Hash>
        #     * Charset <~String>
        #     * Data <~String>
        # * options <~Hash>:
        #   * ReplyToAddresses <~Array> - The reply-to email address(es) for the message. If the recipient replies to the message, each reply-to address will receive the reply.
        #   * ReturnPath <~String> - The email address to which bounce notifications are to be forwarded. If the message cannot be delivered to the recipient, then an error message will be returned from the recipient's ISP; this message will then be forwarded to the email address specified by the ReturnPath parameter.
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'MessageId'<~String> - Id of message
        #     * 'ResponseMetadata'<~Hash>:
        #       * 'RequestId'<~String> - Id of request
        def send_email(source, destination, message, options = {})
          params = {
            'Source' => source
          }

          for key, values in destination
            params.merge!(Fog::AWS.indexed_param("Destination.#{key}.member", [*values]))
          end

          for key, value in message['Subject']
            params["Message.Subject.#{key}"] = value
          end

          for type, data in message['Body']
            for key, value in data
              params["Message.Body.#{type}.#{key}"] = value
            end
          end

          if options.key?('ReplyToAddresses')
            params.merge!(Fog::AWS.indexed_param("ReplyToAddresses.member", [*options['ReplyToAddresses']]))
          end

          if options.key?('ReturnPath')
            params['ReturnPath'] = options['ReturnPath']
          end

          request({
            'Action'           => 'SendEmail',
            :parser            => Fog::Parsers::AWS::SES::SendEmail.new
          }.merge(params))
        end
      end
    end
  end
end
