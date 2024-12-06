module Fog
  module AWS
    class SES
      class Real
        require 'fog/aws/parsers/ses/delete_verified_email_address'

        # Delete an existing verified email address
        #
        # ==== Parameters
        # * email_address<~String> - Email Address to be removed
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'ResponseMetadata'<~Hash>:
        #       * 'RequestId'<~String> - Id of request
        def delete_verified_email_address(email_address)
          request({
            'Action'           => 'DeleteVerifiedEmailAddress',
            'EmailAddress'     => email_address,
            :parser            => Fog::Parsers::AWS::SES::DeleteVerifiedEmailAddress.new
          })
        end
      end
    end
  end
end
