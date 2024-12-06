module Fog
  module AWS
    class SES
      class Real
        require 'fog/aws/parsers/ses/verify_domain_identity'

        # Verifies a domain. This action returns a verification authorization
        # token which must be added as a DNS TXT record to the domain.
        #
        # ==== Parameters
        # * domain<~String> - The domain to be verified
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'ResponseMetadata'<~Hash>:
        #       * 'VerificationToken'<~String> - Verification token
        #       * 'RequestId'<~String> - Id of request
        def verify_domain_identity(domain)
          request({
            'Action'           => 'VerifyDomainIdentity',
            'Domain'           => domain,
            :parser            => Fog::Parsers::AWS::SES::VerifyDomainIdentity.new
          })
        end
      end
    end
  end
end
